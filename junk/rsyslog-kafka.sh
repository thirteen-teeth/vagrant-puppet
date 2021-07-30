#!/bin/bash

dnf -y install rsyslog-kafka

semanage port -a -t syslogd_port_t -p tcp 9092
semanage port -a -t syslog_tls_port_t -p tcp 9092

se_tmp="/tmp/selinux"
te_file="${se_tmp}/my-rdkbroker1.te"
mod_file="${se_tmp}/my-rdkbroker1.mod"
pp_file="${se_tmp}/my-rdkbroker1.pp"

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