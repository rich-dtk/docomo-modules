# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class hadoop {

  /**
   * Common definitions for hadoop nodes.
   * They all need these files so we can access hdfs/jobs from any node
   */
   
  class kerberos {
    require kerberos::client

    kerberos::host_keytab { "hdfs":
      princs => [ "host", "hdfs" ],
      spnego => true,
    }
   
    kerberos::host_keytab { [ "yarn", "mapred" ]:
      tag    => "mapreduce",
      spnego => true,
    }
  }

  class common {
    #TODO: just templ for testing; dont want cross module includes typically

    include hadoop::params
    include bigtop_base

    if ($auth == "kerberos") {
      include hadoop::kerberos
    }
#  if $hadoop::params::ganglia_metrics {
#    file  { '/etc/hadoop/conf/hadoop-metrics.properties':
#      content => template('hadoop/hadoop-metrics.properties-ganglia.erb'),
#      owner   => $hadoop::params::hdfs_user,
#      group   => $hadoop::params::hdfs_user_group,
#      require => [Package['hadoop']]
#    }
#  }

  #TODO: make paramterized
  $ganglia_metric_host = '192.168.200.41'
  $ganglia_metric_port = 8649

  if $ganglia_metric_host != undef {
    file  { '/etc/hadoop/conf/hadoop-metrics2.properties':
      content => template('hadoop/hadoop-metrics2.properties-ganglia.erb'),
      owner   => $hadoop::params::hdfs_user,
      group   => $hadoop::params::hdfs_user_group,
      require => [Package['hadoop']]
    }
  }

    file {
      "/etc/hadoop/conf/hadoop-env.sh":
        content => template('hadoop/hadoop-env.sh'),
        require => [Package["hadoop"]],
    }

    package { "hadoop":
      ensure => latest,
      require => Package["jdk"],
    }

    #FIXME: package { "hadoop-native":
    #  ensure => latest,
    #  require => [Package["hadoop"]],
    #}
  }

  class common-yarn inherits common {
    package { "hadoop-yarn":
      ensure => latest,
      require => [Package["jdk"], Package["hadoop"]]
    }

   #TODO: hack fix so data-driven
    include hadoop::params
    if $hadoop::params::hadoop_version == '2.3' {
      $yarn_template_path = 'hadoop/v2.3/yarn-site.xml'
    } else {
      $yarn_template_path = 'hadoop/yarn-site.xml'
    }

    file {
      "/etc/hadoop/conf/yarn-site.xml":
        content => template($yarn_template_path),
        require => [Package["hadoop"]],
    }

    file { "/etc/hadoop/conf/container-executor.cfg":
      content => template('hadoop/container-executor.cfg'), 
      require => [Package["hadoop"]],
    }
  }

  class common_hdfs inherits common {
    if ($auth == "kerberos" and $ha != "disabled") {
      fail("High-availability secure clusters are not currently supported")
    }

    include ::hadoop::params

    $hdfs_user = $::hadoop::params::default_user
    $hdfs_user_group = $::hadoop::params::default_user_group     
    File<|tag == 'hdfs_file'|>{
      owner   => $hdfs_user,
      group   => $hdfs_user_group
    }


    if ($ha != 'disabled') {
      $nameservice_id = extlookup("hadoop_ha_nameservice_id", "ha-nn-uri")
    }

    package { "hadoop-hdfs":
      ensure => latest,
      require => [Package["jdk"], Package["hadoop"]],
    }
 
    file {
      "/etc/hadoop/conf/core-site.xml":
        content => template('hadoop/core-site.xml'),
        require => [Package["hadoop"]],
        tag     => 'hdfs_file',
    }

    file {
      "/etc/hadoop/conf/hdfs-site.xml":
        content => template('hadoop/hdfs-site.xml'),
        require => [Package["hadoop"]],
        tag     => 'hdfs_file',
    }
    file { '/var/lib/hadoop-hdfs':
      require => [Package["hadoop"]],
      tag     => 'hdfs_file',
    }
  }

  class common-mapred-app inherits common_hdfs {
    include bigtop_base
    $mapred_framework = $bigtop_base::mapred_framework

    package { "hadoop-mapreduce":
      ensure => latest,
      require => [Package["jdk"], Package["hadoop"]],
    }

    file {
      "/etc/hadoop/conf/mapred-site.xml":
        content => template('hadoop/mapred-site.xml'),
        require => [Package["hadoop"]],
    }

    file { "/etc/hadoop/conf/taskcontroller.cfg":
      content => template('hadoop/taskcontroller.cfg'), 
      require => [Package["hadoop"]],
    }
  }

  define httpfs ($namenode_host, $namenode_port, $port = "14000", $auth = "simple", $secret = "hadoop httpfs secret") {

    $hadoop_namenode_host = $namenode_host
    $hadoop_namenode_port = $namenode_port
    $hadoop_httpfs_port = $port
    $hadoop_security_authentication = $auth

    if ($auth == "kerberos") {
      kerberos::host_keytab { "httpfs":
        spnego => true,
      }
    }

    package { "hadoop-httpfs":
      ensure => latest,
      require => Package["jdk"],
    }

    file { "/etc/hadoop-httpfs/conf/httpfs-site.xml":
      content => template('hadoop/httpfs-site.xml'),
      require => [Package["hadoop-httpfs"]],
    }

    file { "/etc/hadoop-httpfs/conf/httpfs-env.sh":
      content => template('hadoop/httpfs-env.sh'),
      require => [Package["hadoop-httpfs"]],
    }

    file { "/etc/hadoop-httpfs/conf/httpfs-signature.secret":
      content => inline_template("<%= secret %>"),
      require => [Package["hadoop-httpfs"]],
    }

    service { "hadoop-httpfs":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-httpfs"], File["/etc/hadoop-httpfs/conf/httpfs-site.xml"], File["/etc/hadoop-httpfs/conf/httpfs-env.sh"], File["/etc/hadoop-httpfs/conf/httpfs-signature.secret"]],
      require => [ Package["hadoop-httpfs"] ],
    }
    Kerberos::Host_keytab <| title == "httpfs" |> -> Service["hadoop-httpfs"]
  }

  class kinit {
    include hadoop::kerberos

    exec { "HDFS kinit":
      command => "/usr/bin/kinit -kt /etc/hdfs.keytab hdfs/$ipaddress && /usr/bin/kinit -R",
      user    => "hdfs",
      require => Kerberos::Host_keytab["hdfs"],
    }
  }

  define create_hdfs_dirs($hdfs_dirs_meta, $auth="simple") {
    $user = $hdfs_dirs_meta[$title][user]
    $perm = $hdfs_dirs_meta[$title][perm]

    if ($auth == "kerberos") {
      require hadoop::kinit
      Exec["HDFS kinit"] -> Exec["HDFS init $title"]
    }

    exec { "HDFS init $title":
      user => "hdfs",
      command => "/bin/bash -c 'hadoop fs -mkdir $title && hadoop fs -chmod $perm $title && hadoop fs -chown $user $title'",
      unless => "/bin/bash -c 'hadoop fs -ls $name >/dev/null 2>&1'",
      require => Service["hadoop-hdfs-namenode"],
    }
    Exec <| title == "activate nn1" |>  -> Exec["HDFS init $title"]
  }

  define namedir_copy ($source, $ssh_identity) {
    exec { "copy namedir $title from first namenode":
      command => "/usr/bin/rsync -avz -e '/usr/bin/ssh -oStrictHostKeyChecking=no -i $ssh_identity' '${source}:$title/' '$title/'",
      user    => "hdfs",
      tag     => "namenode-format",
      creates => "$title/current/VERSION",
    }
  }
      
  define secondarynamenode ($namenode_host, $namenode_port, $port = "50090", $auth = "simple") {

    $hadoop_secondarynamenode_port = $port
    $hadoop_security_authentication = $auth

    include common_hdfs

    package { "hadoop-hdfs-secondarynamenode":
      ensure => latest,
      require => Package["jdk"],
    }

    file {
      "/etc/default/hadoop-hdfs-secondarynamenode":
        content => template('hadoop/hadoop-hdfs'),
        require => [Package["hadoop-hdfs-secondarynamenode"]],
    }

    service { "hadoop-hdfs-secondarynamenode":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-hdfs-secondarynamenode"], File["/etc/hadoop/conf/core-site.xml"], File["/etc/hadoop/conf/hdfs-site.xml"], File["/etc/hadoop/conf/hadoop-env.sh"]],
      require => [Package["hadoop-hdfs-secondarynamenode"]],
    }
    Kerberos::Host_keytab <| title == "hdfs" |> -> Service["hadoop-hdfs-secondarynamenode"]
  }

  define proxyserver ($host = $ipaddress, $port = "8088", $auth = "simple") {
    $hadoop_ps_host = $host
    $hadoop_ps_port = $port
    $hadoop_security_authentication = $auth

    include common-yarn

    package { "hadoop-yarn-proxyserver":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hadoop-yarn-proxyserver":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-yarn-proxyserver"], File["/etc/hadoop/conf/hadoop-env.sh"], 
                    File["/etc/hadoop/conf/yarn-site.xml"], File["/etc/hadoop/conf/core-site.xml"]],
      require => [ Package["hadoop-yarn-proxyserver"] ],
    }
    Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-yarn-proxyserver"]
  }

  define mapred-app ($namenode_host, $namenode_port, $jobtracker_host, $jobtracker_port, $auth = "simple", $jobhistory_host = "", $jobhistory_port="10020", $dirs = ["/tmp/mr"]){
    $hadoop_namenode_host = $namenode_host
    $hadoop_namenode_port = $namenode_port
    $hadoop_jobtracker_host = $jobtracker_host
    $hadoop_jobtracker_port = $jobtracker_port
    $hadoop_security_authentication = $auth

    include common-mapred-app

    if ($jobhistory_host != "") {
      $hadoop_hs_host = $jobhistory_host
      $hadoop_hs_port = $jobhistory_port
    }

    file { $dirs:
      ensure => directory,
      owner => yarn,
      group => yarn,
      mode => 755,
      require => [Package["hadoop-mapreduce"]],
    }
  }
}
 
 
 
 
