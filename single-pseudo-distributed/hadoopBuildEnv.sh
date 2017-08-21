#!/bin/bash

single=$1 #single mode
hadoopFileName="/usr/local/hadoop-2.7.1.tar.gz"
userName="hadoop"
password="fairlink"
hadoopPath="/usr/local/hadoop"

if cat /etc/issue | grep CentOS ; then
         centos="centos"
else
         centos=''
fi

# setup needed software packages
if [ -n "$centos" ]; then
	yum install -y tcl expect sshpass
else
	apt-get install -y tcl expect sshpass
fi

# create hadoop running user
useradd -m $userName -s /bin/bash

if [ -n "$centos" ]; then
	echo $password | passwd --stdin $userName
else
        echo "$userName:$password" | chpasswd
fi

chmod +x expectScriptLogin.sh
chown -R $userName:$userName expectScriptLogin.sh

# create .ssh directory
su - $userName -s /usr/local/scripts/expectScriptLogin.sh localhost $password

su - $userName -c "ssh-keygen -t rsa -P '' -f /home/hadoop/.ssh/id_rsa;cd /home/hadoop/.ssh;cat id_rsa.pub >> authorized_keys;chmod 600 ./authorized_keys"

# fetch hadoop setup package
if [ ! -f "$hadoopFileName" ]; then
	cd /usr/local
        wget https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-2.7.1/hadoop-2.7.1.tar.gz
fi

cd /usr/local
tar -zxf hadoop-2.7.1.tar.gz
mv hadoop-2.7.1/ /usr/local/hadoop/
chown -R $userName:$userName $hadoopPath

# add environment variables
su - $userName -c "echo \"export HADOOP_HOME=/usr/local/hadoop\" >> ~/.bashrc;echo \"export PATH=$PATH:$hadoopPath/sbin:$hadoopPath/bin\" >> ~/.bashrc;source ~/.bashrc"

if [ ! -n "$single" ]; then
	sed -i "/<configuration>/a\<property>\n<name>fs.defaultFS</name>\n<value>hdfs://$HOSTNAME:9000</value>\n</property>\n<property>\n<name>hadoop.tmp.dir</name>\n<value>$hadoopPath/tmp</value>\n</property>" $hadoopPath/etc/hadoop/core-site.xml
	sed -i "/<configuration>/a\<property>\n<name>dfs.replication</name>\n<value>1</value>\n</property>\n<property>\n<name>dfs.namenode.name.dir</name>\n<value>$hadoopPath/hdfs/name</value>\n</property>\n<property>\n<name>dfs.datanode.data.dir</name>\n<value>$hadoopPath/hdfs/data</value>\n</property>" $hadoopPath/etc/hadoop/hdfs-site.xml
fi

if [ $JAVA_HOME ]; then
        echo $JAVA_HOME
        sed -i "/export JAVA_HOME/d" $hadoopPath/etc/hadoop/hadoop-env.sh
        sed -i "/# The java implementation/a\export JAVA_HOME=$JAVA_HOME" $hadoopPath/etc/hadoop/hadoop-env.sh
fi
