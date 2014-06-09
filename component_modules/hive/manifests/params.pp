# /etc/puppet/modules/hive/manafests/params.pp

class hive::params {

	include java::params

	$version = $::hostname ? {
                default                 => "0.10.0",
	}

 	$hive_user = $::hostname ? {
         #link to bigtop default
		default			=> "hdfs",
	}
 
 	$hadoop_group = $::hostname ? {
         #link to bigtop default
		default			=> "hdfs",
	}
        
	$java_home = $::hostname ? {
		default			=> "/usr/lib/jvm/java-1.7.0",
	}

	$hadoop_base = $::hostname ? {
		default			=> "/usr/lib",
	}
 
	$hadoop_conf = $::hostname ? {
		default			=> "/etc/hadoop/conf",
	}
 
	$hive_base = $::hostname ? {
		default			=> "/opt/hive",
	}
 
	$hive_conf = $::hostname ? {
		default			=> "${hive_base}/hive/conf",
	}
 
    $hive_user_path = $::hostname ? {
		default			=> "/home/${hive_user}",
	}             

    $mysql_connector_java = $operatingsystem ? {
        ubuntu => libmysql-java,
        redhat => mysql-connector-java,
        centos => mysql-connector-java,
    }
 
    $mysql_connector_java_jar = $operatingsystem ? {
        ubuntu => "/usr/share/java/mysql-connector-java.jar",
        redhat => "/usr/share/java/mysql-connector-java.jar",
        centos => "/usr/share/java/mysql-connector-java.jar",
    }

    $metastore_server = $::hostname ? {
        default         => "localhost",
    }

    $metastore_host = $::hostname ? {
        default         => "localhost",
    }

    $metastore_password = $::hostname ? {
        default         => "hive545",
    }

}
