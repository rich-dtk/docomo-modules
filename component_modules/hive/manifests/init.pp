# /etc/puppet/modules/hive/manafests/init.pp

class hive(
  $version = $version
) inherits hive::params
{

  if $version == '0.13.0' {
     $hive_env_sh_erb = "hive/${version}/hive-env.sh.erb"
     $hive_aux_jars_path = '/usr/share/java'
  } else {
     $hive_env_sh_erb = undef
     $hive_aux_jars_path = ''
  }

# group { $hadoop_group:
# 	ensure => present,
# 	gid => "800"
# }
# 
# user { $hive_user:
# 	ensure => present,
# 	comment => "Hadoop",
# 	password => "!!",
# 	uid => "800",
# 	gid => "800",
# 	shell => "/bin/bash",
# 	home => $hive_user_path,
# 	require => Group["hadoop"],
# }
# 
# file { $hive_user_path:
# 	ensure => "directory",
# 	owner => $hive_user,
# 	group => $hadoop_group,
# 	alias => "${hive_user}-home",
# 	require => [ User[$hive_user], Group["hadoop"] ]
# }

  #TODO: hacks to clean up
  #avoid SLF4J: Class path contains multiple SLF4J bindings message
  $zk_file_to_mv = '/usr/lib/zookeeper/lib/slf4j-log4j12-1.6.1.jar'
  exec { 'avoid multiple SLF4J bindings': 
    command => "mv ${zk_file_to_mv} ${zk_file_to_mv}.mv",
    onlyif  => "test -f ${zk_file_to_mv}",
    creates => "${zk_file_to_mv}.mv",
    path    => ['/bin','/usr/bin']
  }
  
  file { "/home/${hive_user}":
    ensure => 'directory',
    owner  => $hive_user,
    group  => $hadoop_group
  }
  file { "/home/${hive_user}/.bashrc":
    owner   => $hive_user,
    group   => $hadoop_group,
    mode    => '0644',
    content => template('hive/bashrc.erb'),
    require => File["/home/${hive_user}"]
  }

	file {"${hive_base}":
		ensure => "directory",
		owner => $hive_user,
		group => $hadoop_group,
		alias => "hive-base",
	}

 	file {"${hive_conf}":
		ensure => "directory",
		owner => $hive_user,
		group => $hadoop_group,
		alias => "hive-conf",
        require => [File["hive-base"], Exec["untar-hive"]],
        before => [File["hive-site-xml"], File["hive-init-sh"]]
	}
 
	file { "${hive_base}/hive-${version}.tar.gz":
		mode => 0644,
		owner => $hive_user,
		group => $hadoop_group,
		source => "puppet:///modules/hive/hive-${version}.tar.gz",
		alias => "hive-source-tgz",
		before => Exec["untar-hive"],
		require => File["hive-base"]
	}
	
	exec { "untar hive-${version}.tar.gz":
		command => "tar xfvz hive-${version}.tar.gz",
		cwd => "${hive_base}",
		creates => "${hive_base}/hive-${version}",
		alias => "untar-hive",
		refreshonly => true,
		subscribe => File["hive-source-tgz"],
		user => $hive_user,
		before => [ File["hive-symlink"], File["hive-app-dir"]],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
	}

	file { "${hive_base}/hive-${version}":
		ensure => "directory",
		mode => 0644,
		owner => $hive_user,
		group => $hadoop_group,
		alias => "hive-app-dir",
        require => Exec["untar-hive"],
	}
		
	file { "${hive_base}/hive":
		force => true,
		ensure => "${hive_base}/hive-${version}",
		alias => "hive-symlink",
		owner => $hive_user,
		group => $hadoop_group,
		require => File["hive-source-tgz"],
		before => [ File["hive-site-xml"], File["hive-init-sh"] ]
	}
	
	file { "${hive_base}/hive-${version}/conf/hive-site.xml":
		owner => $hive_user,
		group => $hadoop_group,
		mode => "644",
		alias => "hive-site-xml",
        require => File["hive-app-dir"],
		content => template("hive/hive-site.xml.erb"),
	}
 
	file { "${hive_base}/hive-${version}/conf/init.sh":
		owner => $hive_user,
		group => $hadoop_group,
		mode => "744",
		alias => "hive-init-sh",
        require => File["hive-app-dir"],
		content => template("hive/init.sh.erb"),
	}

 	exec { "initiate hive":
		command => "./init.sh",
		cwd => "${hive_base}/hive-${version}/conf",
		alias => "init-hive",
		user => $hive_user,
		require => [File["hive-init-sh"]],
        path    => ["/bin", "/usr/bin", "/usr/sbin", "${hive_base}/hive-${version}/conf", "${hadoop_base}/hadoop/bin"],
	}

	file { "${hive_base}/hive-${version}/conf/mysql.sql":
	  owner   => $hive_user,
	  group   => $hadoop_group,
	  mode    => '644',
	  content => template("hive/mysql.sql.erb"),
          require => File["hive-app-dir"],
	}

 	exec { "set hive_home":
		command => "echo 'export HIVE_HOME=${hive_base}/hive-${version}' >> ${hive_user_path}/.bashrc",
		alias => "set-hivehome",
        creates => "${hive_base}/hive/lib/libmysql-java.jar",
		user => $hive_user,
		require => [File["hive-app-dir"]],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
	}
 
 	exec { "set hive path":
		command => "echo 'export PATH=\$PATH:${hive_base}/hive-${version}/bin' >> ${hive_user_path}/.bashrc",
		alias => "set-hivepath",
        creates => "${hive_base}/hive/lib/libmysql-java.jar",
		user => $hive_user,
		before => Exec["set-hivehome"],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
	}
 
    package { $mysql_connector_java:
        ensure  => installed,
        alias   => "mysql-connector-java",
        require => [File["hive-app-dir"]],
    }

    file { "${hive_base}/hive/lib/libmysql-java.jar":
        force => true,
        ensure => $mysql_connector_java_jar,
        alias => "libmysql-symlink",
        owner => $hive_user,
        group => $hadoop_group,
        require => Package[$mysql_connector_java],
    }

}
