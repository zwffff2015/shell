#!/bin/bash

# To build one of the nodes of the hadoop full distributed environment

isNode=$1

userName="hadoop"
password="fairlink"
hadoopPath="/usr/local/hadoop"
masterHostName="esxi-node-002"
node1HostName="esxi-node-001"
node2HostName="esxi-node-054"

# setup needed software packages
yum install -y tcl expect sshpass

# create hadoop running user
useradd -m $userName -s /bin/bash
echo $password | passwd --stdin $userName

chmod +x expectScriptLogin.sh
chown -R $userName:$userName expectScriptLogin.sh

sed -i '$a\192.168.11.144  esxi-node-002\n192.168.10.55   esxi-node-001\n192.168.11.56  esxi-node-054' /etc/hosts

# create .ssh directory
su - $userName -s /usr/local/scripts/expectScriptLogin.sh localhost $password

su - $userName -c "ssh-keygen -t rsa -P '' -f /home/hadoop/.ssh/id_rsa;cd /home/hadoop/.ssh;cat id_rsa.pub >> authorized_keys;chmod 600 ./authorized_keys"

# test to log in master machine
su - root -s /usr/local/scripts/expectScriptLogin.sh $masterHostName $password 
	
# fetch hadoop setup package
cd /home/$userName
sshpass -p $password scp root@192.168.11.144:/usr/local/hadoop-2.7.1.tar.gz .
tar -zxvf hadoop-2.7.1.tar.gz
mv hadoop-2.7.1/ /usr/local/hadoop/
chown -R $userName:$userName $hadoopPath

# add environment variables
su - $userName -c "echo \"export HADOOP_HOME=/usr/local/hadoop\" >> ~/.bashrc;echo \"export PATH=$PATH:$hadoopPath/sbin:$hadoopPath/bin\" >> ~/.bashrc;source ~/.bashrc"

sed -i "/<configuration>/a\<property>\n<name>fs.default.name</name>\n<value>hdfs://$masterHostName:9000</value>\n</property>\n<property>\n<name>hadoop.tmp.dir</name>\n<value>$hadoopPath/tmp</value>\n</property>" $hadoopPath/etc/hadoop/core-site.xml
sed -i "/<configuration>/a\<property>\n<name>dfs.replication</name>\n<value>2</value>\n</property>\n<property>\n<name>dfs.namenode.name.dir</name>\n<value>$hadoopPath/hdfs/name</value>\n</property>\n<property>\n<name>dfs.datanode.data.dir</name>\n<value>$hadoopPath/hdfs/data</value>\n</property>" $hadoopPath/etc/hadoop/hdfs-site.xml
cp $hadoopPath/etc/hadoop/mapred-site.xml.template $hadoopPath/etc/hadoop/mapred-site.xml
sed -i "/<configuration>/a\<property>\n<name>mapred.job.tracker</name>\n<value>$masterHostName:9001</value>\n</property>" $hadoopPath/etc/hadoop/mapred-site.xml
echo "$node1HostName" >> $hadoopPath/etc/hadoop/slaves
echo "$node2HostName" >> $hadoopPath/etc/hadoop/slaves

if [ -n "$isNode" ]; then
	sshpass -p $password scp root@192.168.11.144:/home/hadoop/.ssh/authorized_keys /home/hadoop/.ssh/
	chmod 600 /home/hadoop/.ssh/authorized_keys
fi

if [ $JAVA_HOME ]; then
	echo $JAVA_HOME
	sed -i "/export JAVA_HOME/d" $hadoopPath/etc/hadoop/hadoop-env.sh
	sed -i "/# The java implementation/a\export JAVA_HOME=$JAVA_HOME" $hadoopPath/etc/hadoop/hadoop-env.sh 
fi
