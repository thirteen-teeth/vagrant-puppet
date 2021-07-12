#!/bin/bash

dnf -y install https://yum.puppet.com/puppet6-release-el-8.noarch.rpm
dnf -y install vim bash-completion tree setroubleshoot puppet

if [ -z "$1" ]; then
  my_role='default'
else
  my_role=$1
fi

cat << EOF >> /etc/puppetlabs/puppet/puppet.conf
[main]
server = master.puppetdomain
certname = ${HOSTNAME}
runinterval = 30m
EOF

cat << EOF > /etc/puppetlabs/puppet/csr_attributes.yaml
extension_requests:
  pp_role: ${my_role}
  pp_environment: development
EOF

/opt/puppetlabs/bin/puppet agent -t
exit 0