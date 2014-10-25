# == Class: pvc::agent
#
# pvc agent for hosts
#
# === Parameters
#
# === Variables
#
# === Examples
#
#  class { pvc:: pvc_url => 'http://jj.e.com./host' } class { pvc::agent: }
#
# === Authors
#
# John Jawed <jj@x.com>
#
class pvc::agent {

  $pvcagent = '/usr/local/bin/pvc.sh'
  $pidfile = '/var/run/pvc.pid'
  # subshells need the signal too 
  $stop = "/usr/bin/pkill -f ${pvcagent}"
  $start = "/usr/bin/nohup ${pvcagent} 2>&1 >> /var/log/pvc.log &"

  file { '/etc/pvc.conf':
     ensure   => file,
     content  => template("${module_name}/pvc.conf.erb"),
     mode     => 0555,
  }
  ->
  file { $pvcagent:
     ensure   => file,
     source   => "puppet:///modules/${module_name}/pvc.sh",
     mode     => 0555,
  }
  ~>
  service { 'pvcagent':
    provider   => base,
    ensure     => 'running',
    start      => $start,
    stop       => $stop,
    hasrestart => true,
    status     => "/bin/ps -Fp `/bin/cat ${pidfile}` | /bin/grep ${pvcagent}",
  }

}
