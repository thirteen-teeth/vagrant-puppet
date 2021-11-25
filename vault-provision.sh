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
vault operator init -key-shares=1 -key-threshold=1 >> /opt/vault_data/full_output.txt

unseal_key=$(grep 'Unseal Key 1' /opt/vault_data/full_output.txt | awk '{print $NF}')
echo $unseal_key > /opt/vault_data/unseal_key
initial_token=$(grep 'Initial Root Token' /opt/vault_data/full_output.txt | awk '{print $NF}')
echo $initial_token > /opt/vault_data/initial_token
export VAULT_TOKEN=$initial_token
set -x
vault operator unseal $unseal_key
vault secrets enable consul
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki

vault write -field=certificate pki/root/generate/internal \
      common_name="puppetdomain" \
      ttl=87600h > CA_cert.crt

vault write pki/config/urls \
      issuing_certificates="$HOSTNAME/v1/pki/ca" \
      crl_distribution_points="$HOSTNAME/v1/pki/crl"

vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int

vault write -format=json pki_int/intermediate/generate/internal \
      common_name="puppetdomain Intermediate Authority" \
      | jq -r '.data.csr' > pki_intermediate.csr

vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
      format=pem_bundle ttl="43800h" \
      | jq -r '.data.certificate' > intermediate.cert.pem

vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

vault write pki_int/config/urls \
      issuing_certificates="$HOSTNAME/v1/pki_int/ca" \
      crl_distribution_points="$HOSTNAME/v1/pki_int/crl"


#      allowed_domains="puppetdomain" \
#      allow_subdomains=true \
vault write pki_int/roles/puppetdomain \
      allow_any_name=true \
      max_ttl="720h"

exit 0

#export VAULT_ADDR=http://vault-01.puppetdomain:8200
#export PATH=$PATH:/usr/local/bin
#initial_token=$(cat /opt/vault_data/full_output.txt | sed -n '3 p' | awk {'print $(NF)'})
#export VAULT_TOKEN=$initial_token
