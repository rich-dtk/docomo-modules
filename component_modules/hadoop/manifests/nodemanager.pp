#TODO: update to use common params
class hadoop::nodemanager (
  $rm_host, 
  $rm_port, 
  $rt_port, 
  $sc_port = "8030",
  $auth    = "simple"
) inherits hadoop::params
{
  $dirs = $yarn_data_dirs

  $yarn_data_dirs = $dirs
  $hadoop_rm_host = $rm_host
  $hadoop_rm_port = $rm_port
  $hadoop_rt_port = $rt_port
  $hadoop_security_authentication = $auth
  $hadoop_sc_port = $sc_port
  include common-yarn

  package { "hadoop-yarn-nodemanager":
    ensure => latest,
    require => Package["jdk"],
  }

  #TODO: put below in which can preclude some topologies
  package { "hadoop-mapreduce":
    ensure => latest,
    require => Package["jdk"]
  }
 
  service { "hadoop-yarn-nodemanager":
    ensure => running,
    hasstatus => true,
    subscribe => [Package["hadoop-yarn-nodemanager"], File["/etc/hadoop/conf/hadoop-env.sh"], 
                  File["/etc/hadoop/conf/yarn-site.xml"]],
#TODO: lose some robustness by taking this out: File["/etc/hadoop/conf/core-site.xml"]],

    require => [ Package["hadoop-yarn-nodemanager"], Package["hadoop-mapreduce"], File[$dirs] ],
  }
  # Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-yarn-nodemanager"]

  file { $dirs:
    ensure => directory,
    owner => yarn,
    group => yarn,
    mode => 755,
    require => [Package["hadoop-yarn"]],
  }
}
