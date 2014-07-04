class spark::slave(
  $spark_master_host,
  $enable = 'running', 
) inherits spark::params 
{
  class { 'spark':
    spark_master_host => $spark_master_host
  }
  $spark_master_host_name = 'BD-SERV-A-042' #!!!!! hard coded
  $worker_class = 'org.apache.spark.deploy.worker.Worker'
  if $enable == 'running' {
    $start_worker = "${spark_home}/sbin/start-worker.sh"
    file { $start_worker:
      content => template('spark/start-worker.sh.erb'),
      mode    => '0755',
      require => Class['spark']
    }
    exec { 'start-spark-slave':
     command => $start_worker,
     user    => $spark_user,
     unless  => "pgrep -f ${worker_class}",
     path    => ['/bin','/usr/bin'],
     require => [Class['spark'],File[$start_worker]]
    }
  } elsif $enable == 'stopped' {
    exec { 'stop-spark-slave':
      command => "pkill -9 -f ${worker_class}",
      onlyif  => "pgrep -f ${worker_class}",
      path    => ['/bin','/usr/bin']
    }
  }
}