class impala::params() #TODO: inherit from bigtop
{
  $default_config = '/etc/default/impala'
  $config_dir = '/etc/impala/conf'
 
  $hive_thrift_port = 10000

  $hadoop_conf_dir = '/etc/hadoop/conf'
}