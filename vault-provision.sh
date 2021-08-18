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

#export VAULT_ADDR=http://localhost:8200
#export PATH=$PATH:/usr/local/bin
#vault operator init -key-shares=1 -key-threshold=1
#parse output
#and store as files in /opt/vault_data

#Unseal Key 1: t71jZbN3Dn668B0JNKRv/G7eBbou2Ib2v2fOTxdODYI=
#
#Initial Root Token: s.F0vYbtf8DIhXM3yKFIqc7JeI
#
#Vault initialized with 1 key shares and a key threshold of 1. Please securely
#distribute the key shares printed above. When the Vault is re-sealed,
#restarted, or stopped, you must supply at least 1 of these keys to unseal it
#before it can start servicing requests.
#
#Vault does not store the generated master key. Without at least 1 keys to
#reconstruct the master key, Vault will remain permanently sealed!
#
#It is possible to generate new unseal keys, provided you have a quorum of
#existing unseal keys shares. See "vault operator rekey" for more information.

#vault login token=

exit 0
