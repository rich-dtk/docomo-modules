class hadoop::params() inherits bigtop_base::params
{
  #core
  $hadoop_config_io_file_buffer_size = 65536

  #hdfs
  $hadoop_config_dfs_block_size = 134217728
  $hadoop_heapsize = 1000

  $ganglia_metrics = true

}
