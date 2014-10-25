#!/usr/bin/env bash
# to be run on all agent hosts

PIDFILE='/var/run/pvc.pid'

if [ -e ${PIDFILE} ]; then
  rm -rf ${PIDFILE}
fi
echo $$ > ${PIDFILE}

info() {
  if [ $info -gt 0 ]; then
    date +"[%m-%d-%Y %R:%S] [$FUNCNAME] $1"
  fi
}

fatal() {
  date +"[%m-%d-%Y %R:%S] [$FUNCNAME] $1, exiting..."
  exit $2
}

warn() {
  if [ $warnings -gt 0 ]; then
    date +"[%m-%d-%Y %R:%S] [$FUNCNAME] $1"
  fi
}

error() {
  date +"[%m-%d-%Y %R:%S] [$FUNCNAME] $1"
}

http_dependency() {
  v=`which curl`
  http_opts='-s'
  if [ $? -ne 0 ]; then
    v=`which wget`
    http_opts='-qO-'
    if [ $? -ne 0 ]; then
      v=''
    fi
  fi
  if [ -z $v ]; then
    echo ''
  fi
  echo "${v} ${http_opts}"
}

http_post_file() {
  case "${http}" in
    *curl*)
      opts="-X POST -d @${1}"
      ;;
    *wget*)
      opts="--post-file=${1}"
      ;;
  esac
  echo $(http_dependency) ${opts}
}

run_puppet() {
  outfile='/var/tmp/pvc.tmp'
  if [ $1 ]; then
    echo 'true' > ${outfile}
  else
    echo 'false' > ${outfile}
  fi
  puppet agent --enable 2>&1 > /dev/null
  opts=''
  if [ -n ${PVC_PUPPET_MASTER} ]; then
    opts="--server ${PVC_PUPPET_MASTER}"
    info "setting puppet server to ${PVC_PUPPET_MASTER}"
  fi
  $puppet_run $opts 2>&1 | base64 > ${outfile}
  url="${report_endpoint}/${fqdn}"
  o=`$(http_post_file ${outfile}) ${url}`
  info "output of sending puppetrun output='${o}'"
  run_facts
}

run_facts() {
  outfile='/var/tmp/pvc.tmp'
  facter -pj 2>&1 | base64 >> ${outfile}
  url="${facts_endpoint}/${fqdn}"
  o=`$(http_post_file ${outfile}) ${url}`
  info "output of sending facts='${o}'"
}

inotify() {
  p=`which inotifywait`
  if [ $? -eq 0 ]; then
    p="${p} -rq -e close_write -e modify -e create -e delete -e delete_self -t ${1}"
  fi
  echo $p
}

http=$(http_dependency)
fqdn=$(`which facter` fqdn)
: ${PVC_CONF:=/etc/pvc.conf}
: ${info:=0}
puppet_run='puppet agent -t 2>&1'

if [ ! -f $PVC_CONF ]; then
  fatal "Couldn't locate the configuration file @ ${PVC_CONF} (can also be defined via PVC_CONF)" 129
fi

if [ -z "$(inotify 0)" ]; then
  error "inotifywait wasn't found in your PATH (${PATH}) which means files won't be monitored, highly recommended that you install inotify-tools now, you don't need to kill pvc before or after installing."
fi

# only pvc should be allowed to run puppet agent.
puppet agent --disable && info "Disabled puppet agent runs"

trap "echo ; puppet agent --enable && warn 'Caught signal, re-enabled normal puppet runs, exiting pvc.' ; rm ${PIDFILE} ; exit 130 ;" SIGHUP SIGINT SIGTERM

while [ 1 ]; do
  source $PVC_CONF
  : ${PVC_PUPPET_MASTER:=''}
  (
    trap "exit 130" SIGHUP SIGINT SIGTERM
    url="${host_endpoint}/${fqdn}"
    r=`$http $http_opts $url`
    eval $r
    : ${PVC_CHECK_INTERVAL:=5}
    if [[ "${PVC_RETURN}" != "0" ]]; then
      error "Host info request (${url}) failed with an empty or bad return code: ${PVC_RETURN}, will try again in ${PVC_CHECK_INTERVAL}."
      sleep ${PVC_CHECK_INTERVAL}
      exit 1
    fi
    if [[ "${PVC_RUN}" != "0" ]]; then
      run_puppet false
    elif [[ "${PVC_FACT_RUN}" != "0" ]]; then
      run_facts
    fi
    if [ -n "${PVC_FILES_MONITORED}" ]; then
      r=$(inotify $PVC_CHECK_INTERVAL)
      if [ -n "${r}" ]; then
        c="${r} ${PVC_FILES_MONITORED}"
        info "running ${c}"
        o=`$c`
        r=$?
        if [ $r -eq 0 ]; then
          run_puppet true
        elif [ $r -ne 2 ]; then
          error "inotifywait failed to execute properly ($r), the command I tried to run was ${c}, output: ${o}"
        fi
      else
        warn "inotifywait not found in ${PATH}, PVC_FILES_MONITORED=${PVC_FILES_MONITORED} not honored, sleeping instead. Try installing inotify-tools."
        sleep ${PVC_CHECK_INTERVAL}
      fi
    fi
  )
done
