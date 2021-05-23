#!/bin/bash
set -x

dnf makecache
dnf -y install vim bash-completion tree setroubleshoot rsyslog-kafka
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# Kafka install
short="2.8.0"
version="2.13-$short"
url="https://downloads.apache.org/kafka/2.8.0/kafka_$version.tgz"
src_dir="/tmp"
dst_dir="/opt/kafka"

dnf -y install java-11-openjdk

cd $src_dir
curl -O $url
tar xzf kafka_$version.tgz
mv kafka_$version $dst_dir

cat << EOF > /etc/systemd/system/zookeeper.service
[Unit]
Description=Apache Zookeeper server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/bash /opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/usr/bin/bash /opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/systemd/system/kafka.service
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service

[Service]
Type=simple
Environment="JAVA_HOME=/usr/lib/jvm/jre-11-openjdk"
ExecStart=/usr/bin/bash /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/usr/bin/bash /opt/kafka/bin/kafka-server-stop.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now zookeeper.service
systemctl status zookeeper.service
systemctl enable --now kafka.service
systemctl status kafka.service


# Configure topics
topic="rsyslog"
/opt/kafka/bin/kafka-topics.sh --create --topic $topic --bootstrap-server localhost:9092
/opt/kafka/bin/kafka-topics.sh --describe --topic $topic --bootstrap-server localhost:9092

# For debugging to test with
# /opt/kafka/bin/kafka-console-producer.sh --topic $topic --bootstrap-server localhost:9092
# /opt/kafka/bin/kafka-console-consumer.sh --topic $topic --from-beginning --bootstrap-server localhost:9092


#Install rsyslog kafka

dnf -y install rsyslog-kafka

semanage port -a -t syslogd_port_t -p tcp 9092
semanage port -a -t syslog_tls_port_t -p tcp 9092

se_tmp="/tmp/selinux"
te_file="$se_tmp/my-rdkbroker1.te"
mod_file="$se_tmp/my-rdkbroker1.mod"
pp_file="$se_tmp/my-rdkbroker1.pp"

mkdir -p $se_tmp
cat << EOF > $te_file 

module my-rdkbroker1 1.0;

require {
        type unreserved_port_t;
        type syslogd_t;
        class tcp_socket name_connect;
}

#============= syslogd_t ==============

#!!!! This avc can be allowed using the boolean 'nis_enabled'
allow syslogd_t unreserved_port_t:tcp_socket name_connect;
EOF
checkmodule -M -m -o $mod_file $te_file
semodule_package -o $pp_file -m $mod_file
semodule -i $pp_file

rsyslog_kafka_conf="/etc/rsyslog.d/00-kafka.conf"
cat << EOF > $rsyslog_kafka_conf
module(load="omkafka")   # lets you send to Kafka

template(name="json_lines" type="list" option.json="on") {
  constant(value="{")
  constant(value="\"timestamp\":\"")
  property(name="timereported" dateFormat="rfc3339")
  constant(value="\",\"message\":\"")
  property(name="msg")
  constant(value="\",\"host\":\"")
  property(name="hostname")
  constant(value="\",\"severity\":\"")
  property(name="syslogseverity-text")
  constant(value="\",\"facility\":\"")
  property(name="syslogfacility-text")
  constant(value="\",\"syslog-tag\":\"")
  property(name="syslogtag")
  constant(value="\"}")
}

main_queue(
  queue.workerthreads="4"      # threads to work on the queue
  queue.dequeueBatchSize="100" # max number of messages to process at once
  queue.size="10000"           # max queue size
)

action(
  broker=["kafka-host:9092"]
  type="omkafka"
  topic="rsyslog"
  template="json_lines"
)
EOF

systemctl restart rsyslog
systemctl status rsyslog