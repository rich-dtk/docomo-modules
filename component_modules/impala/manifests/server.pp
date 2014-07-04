class impala::server(
  $impala_catalog_host = 'localhost',
  $impala_statestore_host = 'localhost',
) inherits impala::params
{
  #TODO: just works for rhel/centos
  package { 'impala-server': }  

  file { $default_config:
    content => template('impala/default_config.erb'),
    require => Package['impala-server']
  }

  file { "${config_dir}/core-site.xml" :
    ensure => 'link',
    target => "${hadoop_config_dir}/core-site.xml",    
    require => Package['impala-server']
  }

  file { "${config_dir}/hdfs-site.xml" :
    ensure => 'link',
    target => "${hadoop_config_dir}/hdfs-site.xml",    
    require => Package['impala-server']
  }

  service { 'impala-server': 
    ensure     => 'running',
    subscribe => File[$default_config,"${config_dir}/core-site.xml","${config_dir}/hdfs-site.xml"]
  }

}
