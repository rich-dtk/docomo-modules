class hadoop::historyserver(
  $host = $ipaddress, 
  $port = "10020", 
  $webapp_port = "19888", 
  $auth = "simple"
) {
  $hadoop_hs_host = $host
  $hadoop_hs_port = $port
  $hadoop_hs_webapp_port = $webapp_port
  $hadoop_security_authentication = $auth

  #include common-mapred-app
  #TODO: hack
  $hadoop_jobtracker_host = $ipaddress
  $hadoop_jobtracker_port = '8021'
  $mapred_data_dirs = ["/tmp/mr"]

  file {
    "/etc/hadoop/conf/mapred-site.xml":
      content => template('hadoop/mapred-site.xml'),
      require => [Package["hadoop"]],
  }

  file { "/etc/hadoop/conf/taskcontroller.cfg":
    content => template('hadoop/taskcontroller.cfg'), 
    require => [Package["hadoop"]],
  }

  package { "hadoop-mapreduce-historyserver":
    ensure => latest,
    require => Package["jdk"],
  }

  service { "hadoop-mapreduce-historyserver":
    ensure => running,
    hasstatus => true,
    subscribe => [Package["hadoop-mapreduce-historyserver"], File["/etc/hadoop/conf/hadoop-env.sh"], 
                  File["/etc/hadoop/conf/yarn-site.xml"], File["/etc/hadoop/conf/core-site.xml"]],
    require => [Package["hadoop-mapreduce-historyserver"]],
  }
#  Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-mapreduce-historyserver"]
}


