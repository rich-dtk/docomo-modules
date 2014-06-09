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

class bigtop_base::params {
  $mapred_framework = 'yarn'
  $hadoop_version = '2.3'
  $tar_gz_mirror = 'http://apache.tradebit.com' 
  $hadoop_yumrepo = 'http://archive-primary.cloudera.com/cdh5/redhat/6/x86_64/cdh/5/'
  #$hadoop_yumrepo = 'http://archive.cloudera.com/cdh4/redhat/5/x86_64/cdh/4/'
  #TODO: this looks like not being used
  $default_jdk_package_name = 'java-1.6.0-openjdk'

  $jdk_package_name = extlookup("jdk_package_name", $default_jdk_package_name)
  $jdk_dev_package_name = extlookup("jdk_dev_package_name", "${default_jdk_package_name}-devel")

#  $hadoop_head_node        = extlookup("hadoop_head_node") 
  $standby_head_node = extlookup("standby_head_node", "")
#  $hadoop_gateway_node     = extlookup("hadoop_gateway_node", $hadoop_head_node)

  $hadoop_ha = $standby_head_node ? {
    ""      => disabled,
    default => extlookup("hadoop_ha", "manual"),
  }
  $ha = $hadoop_ha
  
#  $hadoop_namenode_host        = $hadoop_ha ? {
#    "disabled" => $hadoop_head_node,
#    default    => [ $hadoop_head_node, $standby_head_node ],
#  }

#  $hadoop_namenode_port        = extlookup("hadoop_namenode_port", "17020")
  $hadoop_namenode_port        = extlookup("hadoop_namenode_port", "8020")
  $hadoop_namenode_thrift_port = extlookup("hadoop_namenode_thrift_port", "10090")
  $hadoop_dfs_namenode_plugins = extlookup("hadoop_dfs_namenode_plugins", "")
  $hadoop_dfs_datanode_plugins = extlookup("hadoop_dfs_datanode_plugins", "")
  # $hadoop_dfs_namenode_plugins="org.apache.hadoop.thriftfs.NamenodePlugin"
  # $hadoop_dfs_datanode_plugins="org.apache.hadoop.thriftfs.DatanodePlugin"
  $hadoop_ha_nameservice_id    = extlookup("hadoop_ha_nameservice_id", "ha-nn-uri")
  $hadoop_namenode_uri   = $hadoop_ha ? {
    "disabled" => "hdfs://$hadoop_namenode_host:$hadoop_namenode_port",
    default    => "hdfs://${hadoop_ha_nameservice_id}:8020",
  }

 # $hadoop_rm_host        = $hadoop_head_node
  $hadoop_rt_port        = extlookup("hadoop_rt_port", "8025")
  $hadoop_rm_port        = extlookup("hadoop_rm_port", "8040")
  $hadoop_sc_port        = extlookup("hadoop_sc_port", "8030")
  $hadoop_rt_thrift_port = extlookup("hadoop_rt_thrift_port", "9290")

 # $hadoop_hs_host        = $hadoop_head_node
  $hadoop_hs_port        = extlookup("hadoop_hs_port", "10020")
  $hadoop_hs_webapp_port = extlookup("hadoop_hs_webapp_port", "19888")

 # $hadoop_jobtracker_host            = $hadoop_head_node
  $hadoop_jobtracker_port            = extlookup("hadoop_jobtracker_port", "8021")
  $hadoop_jobtracker_thrift_port     = extlookup("hadoop_jobtracker_thrift_port", "9290")
  $hadoop_mapred_jobtracker_plugins  = extlookup("hadoop_mapred_jobtracker_plugins", "")
  $hadoop_mapred_tasktracker_plugins = extlookup("hadoop_mapred_tasktracker_plugins", "")
  $hadoop_ha_zookeeper_quorum        = "${hadoop_head_node}:2181"
  # $hadoop_mapred_jobtracker_plugins="org.apache.hadoop.thriftfs.ThriftJobTrackerPlugin"
  # $hadoop_mapred_tasktracker_plugins="org.apache.hadoop.mapred.TaskTrackerCmonInst"

  $hadoop_core_proxyusers = { oozie => { groups => 'hudson,testuser,root,hadoop,jenkins,oozie,users',  hosts => "${hadoop_head_node},localhost,127.0.0.1" },
                                hue => { groups => 'hudson,testuser,root,hadoop,jenkins,hue,users',    hosts => "${hadoop_head_node},localhost,127.0.0.1" },
                             httpfs => { groups => 'hudson,testuser,root,hadoop,jenkins,httpfs,users', hosts => "${hadoop_head_node},localhost,127.0.0.1" } }

  $hbase_relative_rootdir        = extlookup("hadoop_hbase_rootdir", "/hbase")
  $hadoop_hbase_rootdir = "$hadoop_namenode_uri$hbase_relative_rootdir"
  $hadoop_hbase_zookeeper_quorum = $hadoop_head_node
  $hbase_heap_size               = extlookup("hbase_heap_size", "1024")

  #$giraph_zookeeper_quorum       = $hadoop_head_node

 # $hadoop_zookeeper_ensemble = ["$hadoop_head_node:2888:3888"]

 # $hadoop_oozie_url  = "http://${hadoop_head_node}:11000/oozie"
 # $hadoop_httpfs_url = "http://${hadoop_head_node}:14000/webhdfs/v1"

$hadoop_storage_base = '/hdata'
  # Set from facter if available
  if $hadoop_storage_base == undef {
    $roots              = extlookup("hadoop_storage_directories",split($hadoop_storage_dirs, ";"))
  } else {
    $roots              = $hadoop_storage_base
  }
notice("roots = ${roots}")

  $namenode_data_dirs = extlookup("hadoop_namenode_data_dirs", append_each("/namenode", $roots))
  $hdfs_data_dirs     = extlookup("hadoop_hdfs_data_dirs",     append_each("/hdfs",     $roots))
  $mapred_data_dirs   = extlookup("hadoop_mapred_data_dirs",   append_each("/mapred",   $roots))
  $yarn_data_dirs     = extlookup("hadoop_yarn_data_dirs",     append_each("/yarn",     $roots))

  $hadoop_security_authentication = extlookup("hadoop_security", "simple")
  if ($hadoop_security_authentication == "kerberos") {
    $kerberos_domain     = extlookup("hadoop_kerberos_domain")
    $kerberos_realm      = extlookup("hadoop_kerberos_realm")
    $kerberos_kdc_server = extlookup("hadoop_kerberos_kdc_server")

    include kerberos::client
  }

#  $default_user = 'dfservice'
#  $default_user_group = 'web'
   $default_user = 'hdfs'
   $default_user_group = 'hdfs'
   $default_user_home = "/home/${default_user}"
}
