#!/bin/bash

dnf -y install https://yum.puppet.com/puppet6-release-el-8.noarch.rpm
dnf -y install puppet-agent

if [ -z "$1" ]; then
  my_role='default'
else
  my_role=$1
fi

cat << EOF > /etc/puppetlabs/puppet/puppet.conf
[main]
server = master.puppetdomain
certname = ${HOSTNAME}
runinterval = 30m
EOF

cat << EOF > /etc/puppetlabs/puppet/csr_attributes.yaml
extension_requests:
  pp_role: ${my_role}
  pp_environment: vagrant
EOF

/opt/puppetlabs/bin/puppet agent -t
systemctl start puppet
systemctl enable puppet

export VAULT_ADDR=http://localhost:8200
export PATH=$PATH:/usr/local/bin
vault operator init -key-shares=1 -key-threshold=1 > /opt/vault_data/full_output.txt

unseal_key=$(cat /opt/vault_data/full_output.txt | head -n 1 | awk {'print $(NF)'})
echo $unseal_key > /opt/vault_data/unseal_key
initial_token=$(cat /opt/vault_data/full_output.txt | sed -n '3 p' | awk {'print $(NF)'})
echo $initial_token > /opt/vault_data/initial_token

exit 0
