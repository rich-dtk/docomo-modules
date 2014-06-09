class hadoop::client (
  $namenode_host, 
  $namenode_port, 
#  $jobtracker_host, 
#  $jobtracker_port, 
  $ha             = 'disabled',
  $auth           = "simple"
) inherits hadoop::params  
{
  $hadoop_namenode_host = $namenode_host
  $hadoop_namenode_port = $namenode_port
  $hadoop_jobtracker_host = $jobtracker_host
  $hadoop_jobtracker_port = $jobtracker_port
  $hadoop_security_authentication = $auth

  include common-mapred-app
  
  # FIXME: "hadoop-source", "hadoop-fuse", "hadoop-pipes"
   package { ["hadoop-doc", "hadoop-libhdfs"]:
    ensure   => latest,
    require => [Package["jdk"], Package["hadoop"], Package["hadoop-hdfs"], Package["hadoop-mapreduce"]],  
   }
}
