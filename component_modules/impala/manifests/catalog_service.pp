class impala::catalog_service() inherits impala::params
{
  #TODO: just works for rhel/centos
  package { 'impala-catalog': }  ->

  file { "${config_dir}/hive-site.xml": 
    content => template('impala/impala_hive_site.xml.erb'),
    notify  => Service['impala-catalog']
  } ->

  service { 'impala-catalog': 
    ensure => 'running'
  }
}