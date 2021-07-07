#!/bin/bash

dnf -y install https://yum.puppet.com/puppet6-release-el-8.noarch.rpm
dnf -y install vim bash-completion tree setroubleshoot puppet

cat << EOF >> /etc/puppetlabs/puppet/puppet.conf
[main]
server = master.puppetdomain
certname = ${HOSTNAME}
runinterval = 30m
EOF

cat << EOF > /etc/puppetlabs/puppet/csr_attributes.yaml
extension_requests:
  pp_role: test
  pp_environment: development
EOF