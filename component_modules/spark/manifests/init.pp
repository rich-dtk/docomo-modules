class spark(
  $spark_master_host = $::hostname,
) inherits spark::params
{
  $spark_tar_gz = 'spark-0.9.1-hadoop_2.3.0-cdh5.0.1-bin.tar.gz' #TODO: this is now hard coded
  $spark_version = 'spark-0.9.1' #TODO: this is now hard coded compiled version


  file { "${base_dir_for_spark}/${spark_tar_gz}":
    source => "puppet:///modules/spark/${spark_tar_gz}",
  } ->
	
  exec { "untar ${spark_tar_gz}":
    command => "tar xfvz ${base_dir_for_spark}/${spark_tar_gz}",
    cwd     => $base_dir_for_spark,
    creates => "${base_dir_for_spark}/${spark_version}",
    path    => ["/bin"]
  } ->

  file { $spark_home:
    ensure => 'link',
    target => "${base_dir_for_spark}/${spark_version}",
  } ->

  file { "${spark_home}/conf/spark-env.sh":
    content => template('spark/spark-env.sh.erb')
  }

  file { [$spark_log_dir,$spark_run_dir]:
     ensure => 'directory',
     owner  => $spark_user
  }

}
