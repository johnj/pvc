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

   file { '/usr/local/bin/pvc.sh':
      ensure   => file,
      source   => "puppet:///modules/${module_name}/pvc.sh",
      mode     => 0555,
   }
   ->
   file { '/etc/pvc.conf':
      ensure   => file,
      content  => template("${module_name}/pvc.conf.erb"),
      mode     => 0555,
   }
}
