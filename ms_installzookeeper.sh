#!/bin/bash
# ZooKeeper installation
# Tested on Ubuntu 20,22

echo "Server ID?"
read serv_id
cd /root
apt-get install default-jdk -y
useradd zookeeper -m
usermod --shell /bin/bash zookeeper
random_password=$(openssl rand -base64 12)
echo -e "$random_password\n$random_password" | passwd zookeeper
usermod -aG sudo zookeeper
mkdir /zookeeper
echo "$serv_id" > /zookeeper/myid
chown -R zookeeper:zookeeper /zookeeper/
cd /opt
wget https://dlcdn.apache.org/zookeeper/zookeeper-3.7.1/apache-zookeeper-3.7.1-bin.tar.gz
tar -xf apache-zookeeper-3.7.1-bin.tar.gz
mv apache-zookeeper-3.7.1-bin zookeeper
chown -R zookeeper:zookeeper /opt/zookeeper
cat > /etc/systemd/system/zookeeper.service <<ZOOKEEPER
[Unit]
Description=Zookeeper Daemon
Documentation=http://zookeeper.apache.org
Requires=network.target
After=network.target

[Service]
Type=forking
WorkingDirectory=/opt/zookeeper
User=zookeeper
Group=zookeeper
ExecStart=/opt/zookeeper/bin/zkServer.sh start /opt/zookeeper/conf/zoo.cfg
ExecStop=/opt/zookeeper/bin/zkServer.sh stop /opt/zookeeper/conf/zoo.cfg
ExecReload=/opt/zookeeper/bin/zkServer.sh restart /opt/zookeeper/conf/zoo.cfg
TimeoutSec=30
Restart=on-failure

[Install]
WantedBy=default.target
ZOOKEEPER
systemctl daemon-reload
systemctl enable zookeeper
systemctl start zookeeper