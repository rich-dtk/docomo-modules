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

class hadoop::namenode(
  $host           = $::ipaddress, #TODO: remove after updating r8 meta
  $port           = "8020", 
  $thrift_port    = "10090", 
  $auth           = "simple", 
  $dirs           = [$hadoop::params::namenode_data_dirs], 
  $ha             = 'disabled', 
  $zk             = '',
  $hadoop_rm_host = $::ipaddress
) inherits hadoop::params 
{

    $first_namenode = inline_template("<%= host.to_a[0] %>")
    $hadoop_namenode_host = $host
    $hadoop_namenode_port = $port
    $hadoop_namenode_thrift_port = $thrift_port
    $hadoop_security_authentication = $auth

    include ::hadoop::common_hdfs
    Exec<|tag == 'namenode-format'|>{
      user      => $::hadoop::common_hdfs::hdfs_user,
      group     => $::hadoop::common_hdfs::hdfs_user_group,
      logoutput => 'on_failure',
    }

    if ($ha != 'disabled') {
      $sshfence_user      = extlookup("hadoop_ha_sshfence_user",      "hdfs") 
      $sshfence_user_home = extlookup("hadoop_ha_sshfence_user_home", "/var/lib/hadoop-hdfs")
      $sshfence_keydir    = "$sshfence_user_home/.ssh"
      $sshfence_keypath   = "$sshfence_keydir/id_sshfence"
      $sshfence_privkey   = extlookup("hadoop_ha_sshfence_privkey",   "$extlookup_datadir/hadoop/id_sshfence")
      $sshfence_pubkey    = extlookup("hadoop_ha_sshfence_pubkey",    "$extlookup_datadir/hadoop/id_sshfence.pub")
      $shared_edits_dir   = extlookup("hadoop_ha_shared_edits_dir",   "/hdfs_shared")
      $nfs_server         = extlookup("hadoop_ha_nfs_server",         "")
      $nfs_path           = extlookup("hadoop_ha_nfs_path",           "")

      file { $sshfence_keydir:
        ensure  => directory,
        mode    => '0700',
        require => Package["hadoop-hdfs"],
        tag     => 'hdfs_file',
      }

      file { $sshfence_keypath:
        source  => $sshfence_privkey,
        mode    => '0600',
        before  => Service["hadoop-hdfs-namenode"],
        require => File[$sshfence_keydir],
        tag     => 'hdfs_file',
      }

      file { "$sshfence_keydir/authorized_keys":
        source  => $sshfence_pubkey,
        mode    => '0600',
        before  => Service["hadoop-hdfs-namenode"],
        require => File[$sshfence_keydir],
        tag     => 'hdfs_file',
      }

      file { $shared_edits_dir:
        ensure => directory,
        tag    => 'hdfs_file',
      }

      if ($nfs_server) {
        if (!$nfs_path) {
          fail("No nfs share specified for shared edits dir")
        }

        require nfs::client

        mount { $shared_edits_dir:
          ensure  => "mounted",
          atboot  => true,
          device  => "${nfs_server}:${nfs_path}",
          fstype  => "nfs",
          options => "tcp,soft,timeo=10,intr,rsize=32768,wsize=32768",
          require => File[$shared_edits_dir],
          before  => Service["hadoop-hdfs-namenode"],
        }
      }
    }


    package { "hadoop-hdfs-namenode":
      ensure => latest,
      require => Package["jdk"]
    }

    service { "hadoop-hdfs-namenode":
      ensure => running,
      hasstatus => true,
      subscribe => [Package["hadoop-hdfs-namenode"], File["/etc/hadoop/conf/core-site.xml"], File["/etc/hadoop/conf/hdfs-site.xml"], File["/etc/hadoop/conf/hadoop-env.sh"]],
      require => [Package["hadoop-hdfs-namenode"]],
    } 
    Exec <| tag == "namenode-format" |>         -> Service["hadoop-hdfs-namenode"]
#    Kerberos::Host_keytab <| title == "hdfs" |> -> Service["hadoop-hdfs-namenode"]

    if ($ha == "auto") {
      package { "hadoop-hdfs-zkfc":
        ensure => latest,
        require => Package["jdk"],
      }

      service { "hadoop-hdfs-zkfc":
        ensure => running,
        hasstatus => true,
        subscribe => [Package["hadoop-hdfs-zkfc"], File["/etc/hadoop/conf/core-site.xml"], File["/etc/hadoop/conf/hdfs-site.xml"], File["/etc/hadoop/conf/hadoop-env.sh"]],
        require => [Package["hadoop-hdfs-zkfc"]],
      } 
      Service <| title == "hadoop-hdfs-zkfc" |> -> Service <| title == "hadoop-hdfs-namenode" |>
    }
notice("first_namenode = ${first_namenode}")
    if ($::ipaddress == $first_namenode) {
      exec { "namenode format":
        command => "/bin/bash -c 'yes Y | hdfs namenode -format >> /var/lib/hadoop-hdfs/nn.format.log 2>&1'",
        creates => "${namenode_data_dirs[0]}/current/VERSION",
        require => [ Package["hadoop-hdfs-namenode"], File[$dirs], File["/etc/hadoop/conf/hdfs-site.xml"] ],
        tag     => "namenode-format",
      } 

      if ($ha != "disabled") {
        if ($ha == "auto") {
          exec { "namenode zk format":
            command => "/bin/bash -c 'yes N | hdfs zkfc -formatZK >> /var/lib/hadoop-hdfs/zk.format.log 2>&1 || :'",
            require => [ Package["hadoop-hdfs-zkfc"], File["/etc/hadoop/conf/hdfs-site.xml"] ],
            tag     => "namenode-format",
          }
          Service <| title == "zookeeper-server" |> -> Exec <| title == "namenode zk format" |>
          Exec <| title == "namenode zk format" |>  -> Service <| title == "hadoop-hdfs-zkfc" |>
        } else {
          exec { "activate nn1": 
            command => "/usr/bin/hdfs haadmin -transitionToActive nn1",
            user    => $hdfs_user,
            unless  => "/usr/bin/test $(/usr/bin/hdfs haadmin -getServiceState nn1) = active",
            require => Service["hadoop-hdfs-namenode"],
          }
        }
      }
    } elsif ($ha != "disabled") {
      hadoop::namedir_copy { $namenode_data_dirs: 
        source       => $first_namenode,
        ssh_identity => $sshfence_keypath,
        require      => File[$sshfence_keypath],
      }
    }

    file {
      "/etc/default/hadoop-hdfs-namenode":
        content => template('hadoop/hadoop-hdfs'),
        require => [Package["hadoop-hdfs-namenode"]],
        tag    => 'hdfs_file',
    }
    
    file { $dirs:
      ensure => directory,
      mode => 700,
      require => [Package["hadoop-hdfs"]],
      tag     => 'hdfs_file', 
    }
}
