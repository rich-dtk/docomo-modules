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

class hadoop::resourcemanager(
  $port                 = 8050, 
  $rt_port              = 8025, 
  $sc_port              = 8030, 
  $thrift_port          = 9290, 
  $auth                 = "simple",
  $hadoop_namenode_host = $::ipaddress,
  $hadoop_namenode_port = $hadoop::params::hadoop_namenode_port
) inherits hadoop::params 
{
    $hadoop_rm_host = $ipaddress

    $hadoop_rm_port = $port
    $hadoop_rt_port = $rt_port
    $hadoop_sc_port = $sc_port
    $hadoop_security_authentication = $auth

    include common_hdfs
    include common-yarn

    package { "hadoop-yarn-resourcemanager":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hadoop-yarn-resourcemanager":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-yarn-resourcemanager"], File["/etc/hadoop/conf/hadoop-env.sh"], 
                    File["/etc/hadoop/conf/yarn-site.xml"], File["/etc/hadoop/conf/core-site.xml"]],
      require => [ Package["hadoop-yarn-resourcemanager"] ],
    }
#    Kerberos::Host_keytab <| tag == "mapreduce" |> -> Service["hadoop-yarn-resourcemanager"]
}
