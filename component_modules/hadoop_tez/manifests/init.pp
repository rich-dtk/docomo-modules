class hadoop_tez(
  $version = $hadoop_tez::params::version,
) inherits hadoop_tez::params
{

  $tez_tar_gz = "${tez_lib_base}/tez-${version}.tar.gz"
  $tez_lib_with_version = "${tez_lib_base}/tez-${version}"
  $tez_lib = "${tez_lib_base}/tez"

  #this gets placed in node because of hadoop::resourcemanager dependency
  #TODO: cleaner way to do this
  include hadoop::common-mapred-app

  file { $tez_tar_gz:
    source => "puppet:///modules/hadoop_tez/tez-${version}.tar.gz"
  }

  exec { 'untar-tez':
    command => "tar -xzf ${tez_tar_gz} -C ${tez_lib_base}",
    creates => $tez_lib_with_version,
    path    => ['/bin'],
    require => File[$tez_tar_gz]
  }

  file { $tez_lib:
    ensure  => 'link',
    target  => $tez_lib_with_version,
    require => Exec['untar-tez']
  }

  exec { 'hdfs-tez-libs':
    command => "hadoop fs -mkdir -p ${tez_hdfs_base} && hadoop fs -put ${tez_lib}/* ${tez_hdfs_base}",
    unless  => "hadoop fs -test -e ${tez_hdfs_base}/lib",
    user    => $tez_hdfs_user,
    # /bin is to get /bin/bash
    path    => ['/bin',$hadoop_bin],
    require => File[$tez_lib]
  }

  file { "${hadoop_conf_base}/tez-site.xml":
    content => template('hadoop_tez/tez-site.xml.erb')
  }

  hadoop_tez::hadoop-env_line { "TEZ_JARS=${tez_lib}":} -> 
  hadoop_tez::hadoop-env_line { "TEZ_LIB=${tez_lib}/lib":} ->
  hadoop_tez::hadoop-env_line { "TEZ_CONF=${hadoop_conf_base}":} ->
  hadoop_tez::hadoop-env_line { 'export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$TEZ_CONF:$TEZ_JARS/*:$TEZ_LIB/*':}

}

#TODO: this assumes that the files has been crated already, but wil not restart any hadoop deamon
#TODO: this is non optimal in requires refresh each time because File[$hadoop_env] produces stripped down config and this adds lines
#better solution is concat or have $hadoop_env have a extra lines var that a link def passes in
define hadoop_tez::hadoop-env_line() 
{
  $line = $name
  $hadoop_env = "${hadoop_conf_base}/hadoop-env.sh"
  exec { "add ${line}":
    command => "echo '${line}' >> ${hadoop_env}",
    unless  => "grep '${line}' ${hadoop_env}",
    path    => ['/bin'],
    require => File[$hadoop_env]
  }
}
