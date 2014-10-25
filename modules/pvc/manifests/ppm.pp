# == Class: pvc
#
# pvc monitoring for puppetmasters
#
# === Parameters
#
# [*ruby*]
#   Fully qualified rath to your ruby executable.
#   Defaults to /usr/bin/ruby
#
# [*puppet_rack_path*]
#   Full path to your puppetmasterd rack installation
#   Defaults to /usr/share/puppet/rack/puppetmasterd
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
class pvc::ppm ($ruby='/usr/bin/ruby', $puppet_rack_path='/usr/share/puppet/rack/puppetmasterd', $pvc_timeout=5) {

  file { '/var/lib/puppet/status.rb':
     ensure   => file,
     content  => template("${module_name}/status.rb.erb"),
     mode     => 0555,
  }
  ->
  cron { pvc:
     command     => "${ruby} /var/lib/puppet/status.rb",
     user        => root,
     minute      => '*',
     environment => 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin',
  }

}
