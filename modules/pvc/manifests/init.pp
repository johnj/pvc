# == Class: pvc
#
# pvc monitoring for puppetmasters
#
# === Parameters
#
# [*pvc_ppm_endpoint*]
#   The pvc PPM stats/registration endpoint (usually http://pvc/ppm)
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
#  class { pvc: pvc_health_endpoint => 'http://jj.e.com./ppm' }
#
# === Authors
#
# John Jawed <jj@x.com>
#
class pvc ($pvc_ppm_endpoint, $ruby='/usr/bin/ruby', $puppet_rack_path='/usr/share/puppet/rack/puppetmasterd', $pvc_timeout=5, $pvc_report_interval=5) {

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
