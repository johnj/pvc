# == Class: pvc
#
# pvc monitoring for puppetmasters
#
# === Parameters
#
# [*puppet_rack_path*]
#   puppetmasterd rack app location.
#   Default value is "/usr/share/puppet/rack/puppetmasterd"
#
# [*bind_port*]
#   Port on which pvc status requests should listen for connections.
#   Default value is 8139
#
# [*bind_ip*]
#   IP on which pvc status requests should listen for connections.
#   Default value is 0.0.0.0 which is "all interfaces"
#
# [*ruby*]
#   Fully qualified rath to your ruby executable.
#   Default value is /usr/bin/ruby
#
# === Variables
#
# === Examples
#
#  class { pvc: }
#
# === Authors
#
# John Jawed <jj@x.com>
#
class pvc ($puppet_rack_path='/usr/share/puppet/rack/puppetmasterd', $bind_port='8139', $ruby='/usr/bin/ruby', $bind_ip='0.0.0.0') {

   file {'/var/lib/puppet/status.rb':
      ensure => file,
      source => "puppet:///modules/${module_name}/status.rb",
      mode   => 0555,
   }
   ->
   xinetd::service { 'pvc':
     bind        => $bind_ip,
     port        => $bind_port,
     server      => $ruby,
     server_args => "/var/lib/puppet/status.rb ${puppet_rack_path}",
     socket_type => 'stream',
     protocol    => 'tcp',
     flags       => 'IPv4',
     wait        => 'no',
   }

}
