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

class bigtop_base(
  $hadoop_version         = $bigtop_base::params::hadoop_version,
  $hadoop_yumrepo         = $bigtop_base::params::hadoop_yumrepo,
  $use_yumrepo            = true,
  $include_java_dev_tools = false,
  $mapred_framework       = $bigtop_base::params::mapred_framework
) inherits bigtop_base::params
{
  if $use_yumrepo {
    yumrepo { "Bigtop":
      baseurl  => $hadoop_yumrepo,
      descr    => "Bigtop packages",
      enabled  => 1,
      gpgcheck => 0,
    }
  } else {
    $tar_gz_url = "${tar_gz_mirror}/pub/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz"
    archive { 'hadoop':
      ensure => present,
      url    => $hadoop_tar_gz_url,
      target => '/opt', #TODO: stub
    }
  }


  #TODO: this is just simple rule assuming only default user and group is used
  user { $default_user:
    ensure     => 'present',
    managehome => true,
    home       => $default_user_home 
  }
  if $default_user != $default_user_group {
    group { $default_user_group:
      ensure     => 'present',
      managehome => true
    }
    User<|title == $default_user|>{
      groups  => $default_user_group,
      require => Group[$default_user_group]
    }
  }

  #TODO: installing jdk because of complications of having multiple mnodules need java
  include java

  #TODO: because of http://stackoverflow.com/questions/20390217/mapreduce-job-in-headless-environment-fails-n-times-due-to-am-container-exceptio
  file { '/bin/java':
    ensure => 'link',
    target => '/usr/bin/java'
  }

  service { 'iptables':
    ensure => 'stopped',
    enable => false
  }
}
