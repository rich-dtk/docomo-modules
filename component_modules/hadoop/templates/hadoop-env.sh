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

<% def shell_config(shell_var, *puppet_var)
     puppet_var = puppet_var[0] || shell_var.downcase
     if has_variable? puppet_var
        return "export #{shell_var}=#{scope.lookupvar(puppet_var)}"
     else
        return "#export #{shell_var}="
     end
   end %>
# WARNING: Heavy puppet machinery is involved managing this file,
#          your edits stand no chance
#
# Set Hadoop-specific environment variables here.

# The only required environment variable is JAVA_HOME.  All others are
# optional.  When running a distributed configuration it is best to
# set JAVA_HOME in this file, so that it is correctly defined on
# remote nodes.

# The java implementation to use.  Required.
<%= shell_config("JAVA_HOME", "hadoop_java_home") %>

# Extra Java CLASSPATH elements.  Optional.
<%= shell_config("HADOOP_CLASSPATH") %>

# The maximum amount of heap to use, in MB. Default is 1000.
#<%= shell_config("HADOOP_HEAPSIZE") %>
export HADOOP_HEAPSIZE=<%= @hadoop_heapsize %>
# Extra Java runtime options.  Empty by default.
<%= shell_config("HADOOP_OPTS") %>

# Command specific options appended to HADOOP_OPTS when specified
<%= shell_config("HADOOP_NAMENODE_OPTS") %>
<%= shell_config("HADOOP_SECONDARYNAMENODE_OPTS") %>
<%= shell_config("HADOOP_DATANODE_OPTS") %>
<%= shell_config("HADOOP_BALANCER_OPTS") %>
<%= shell_config("HADOOP_JOBTRACKER_OPTS") %>
<%= shell_config("HADOOP_TASKTRACKER_OPTS") %>

# The following applies to multiple commands (fs, dfs, fsck, distcp etc)
<%= shell_config("HADOOP_CLIENT_OPTS") %>

# Extra ssh options.  Empty by default.
<%= shell_config("HADOOP_SSH_OPTS") %>

# Where log files are stored.  $HADOOP_HOME/logs by default.
<%= shell_config("HADOOP_LOG_DIR") %>

# File naming remote slave hosts.  $HADOOP_HOME/conf/slaves by default.
<%= shell_config("HADOOP_SLAVES") %>

# host:path where hadoop code should be rsync'd from.  Unset by default.
<%= shell_config("HADOOP_MASTER") %>

# Seconds to sleep between slave commands.  Unset by default.  This
# can be useful in large clusters, where, e.g., slave rsyncs can
# otherwise arrive faster than the master can service them.
<%= shell_config("HADOOP_SLAVE_SLEEP") %>

# The directory where pid files are stored. /tmp by default.
<%= shell_config("HADOOP_PID_DIR") %>

# A string representing this instance of hadoop. $USER by default.
<%= shell_config("HADOOP_IDENT_STRING") %>

# The scheduling priority for daemon processes.  See 'man nice'.
<%= shell_config("HADOOP_NICENESS") %>


### WARNING: the following is NOT really optional. It is a shame that stock Hadoop
### hadoop_env.sh doesn't make it clear -- you can NOT turn  com.sun.management.jmxremote off
### and have a working Hadoop cluster.
export HADOOP_NAMENODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_NAMENODE_OPTS"
export HADOOP_SECONDARYNAMENODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_SECONDARYNAMENODE_OPTS"
export HADOOP_DATANODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_DATANODE_OPTS"
export HADOOP_BALANCER_OPTS="-Dcom.sun.management.jmxremote $HADOOP_BALANCER_OPTS"
export HADOOP_JOBTRACKER_OPTS="-Dcom.sun.management.jmxremote $HADOOP_JOBTRACKER_OPTS"

