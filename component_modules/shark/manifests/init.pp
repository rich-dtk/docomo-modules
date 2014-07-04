class shark() inherits shark::params
{
  $shark_version = 'shark-0.9.1-bin-hadoop2-patched1' #TODO: this is now hard coded compiled version
  $shark_expanded_dir_name = 'shark-0.9.1-bin-hadoop2'
  $shark_tar_gz = "${shark_version}.tgz"
  $shark_home = "${spark_user_home}/shark"

  ###!!!!! needs to be changed; neds hostname not ip address
  $spark_master_host = 'BD-SERV-A-042'

  file { $spark_user_home:
    ensure => 'directory'
  } ->

  file { "${spark_user_home}/${shark_tar_gz}":
    source => "puppet:///modules/shark/${shark_tar_gz}",
  } ->
	
  exec { "untar ${shark_tar_gz}":
    command => "tar xfvz ${spark_user_home}/${shark_tar_gz}",
    cwd     => $spark_user_home,
    creates => "${spark_user_home}/${shark_version}",
    path    => ["/bin"]
  } ->

  file { $shark_home:
    ensure => 'link',
    target => "${spark_user_home}/${shark_expanded_dir_name}"
  } ->

  file { "${shark_home}/conf/shark-env.sh":
    content => template('shark/shark-env.sh.erb')
  }

  file { $shark_log_dir:
     ensure => 'directory',
     owner  => $shark_user
  }

}
