# == Class: ganglia::gmetad::config
#
# installs the configuration file for gmetad
#
# === Authors
#
# Joshua Hoblitt <jhoblitt@cpan.org>
#
# === Copyright
#
# Copyright (C) 2012-2013 Joshua Hoblitt
#
class ganglia::gmetad::config {

  $rrd_rootdir = $::ganglia::params::rrd_rootdir
  #TODO: if need 'mkdir -p' this does not work
  file { $rrd_rootdir:
    ensure => 'directory',
    owner  => $::ganglia::params::gmetad_user,
    group  => $::ganglia::params::gmetad_user
  }

  file { $::ganglia::params::gmetad_service_config:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($::ganglia::params::gmetad_service_erb),
    notify  => Class['ganglia::gmetad::service'],
  }
}
