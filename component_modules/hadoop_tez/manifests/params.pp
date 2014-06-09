class hadoop_tez::params() inherits bigtop_base::params
{
  $version = '0.3.0-incubating'
  $tez_lib_base = '/usr/lib'
  $tez_hdfs_base = '/tez'
  $tez_hdfs_user = $bigtop_base::params::default_user

  #TODO: put this in bigtop_base
  $hadoop_conf_base = '/etc/hadoop/conf'
  $hadoop_bin = '/usr/bin'
}