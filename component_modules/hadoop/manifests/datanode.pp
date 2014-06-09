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

class hadoop::datanode (
  $namenode_host, 
  $namenode_port, 
  $port            = "50075", 
  $auth            = "simple", 
  $dirs            = [$hadoop::params::hdfs_data_dirs],
  $ha              = 'disabled',
  $hdfs_user       = $hadoop::params::default_user,
  $hdfs_user_group = $hadoop::params::default_user_group
) inherits hadoop::params
{

    $hadoop_namenode_host           = $namenode_host
    $hadoop_namenode_port           = $namenode_port
    $hadoop_datanode_port           = $port
    $hadoop_security_authentication = $auth

    if ($ha != 'disabled') {
      # Needed by hdfs-site.xml
      $sshfence_keydir  = "/usr/lib/hadoop/.ssh"
      $sshfence_keypath = "$sshfence_keydir/id_sshfence"
      $sshfence_user    = extlookup("hadoop_ha_sshfence_user",    "hdfs") 
      $shared_edits_dir = extlookup("hadoop_ha_shared_edits_dir", "/hdfs_shared")
    }

    include common_hdfs

    package { "hadoop-hdfs-datanode":
      ensure => latest,
      require => Package["jdk"],
    }

    file {
      "/etc/default/hadoop-hdfs-datanode":
        content => template('hadoop/hadoop-hdfs'),
        require => [Package["hadoop-hdfs-datanode"]],
        tag     => 'hdfs_file',
    }

    service { "hadoop-hdfs-datanode":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-hdfs-datanode"], File["/etc/hadoop/conf/core-site.xml"], File["/etc/hadoop/conf/hdfs-site.xml"], File["/etc/hadoop/conf/hadoop-env.sh"]],
      require => [ Package["hadoop-hdfs-datanode"], File[$dirs] ],
    }
#    Kerberos::Host_keytab <| title == "hdfs" |> -> Service["hadoop-hdfs-datanode"]

    file { $dirs:
      ensure => directory,
      mode => 755,
      require => [ Package["hadoop-hdfs"] ],
      tag     => 'hdfs_file',
    }
}

