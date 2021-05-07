#!/bin/bash

# master is provisioned with file resource copy of user's ~.ssh/id_rsa key, move this to the root user for r10k clone
# file resources in vagrant are done by the vagrant user so copying the file to /root/ fails

if [[ ! -d /root/.ssh ]]; then
  echo "Add github.com to known_hosts"
  mkdir -m700 /root/.ssh
  touch /root/.ssh/known_hosts
  ssh-keyscan -H github.com >> /root/.ssh/known_hosts && chmod 600 /root/.ssh/known_hosts
  echo "Adding local user's ~/.ssh/id_rsa to the root user's"
  mv /tmp/id_rsa /root/.ssh/
fi

dnf makecache
# git required for r10k
dnf -y install vim bash-completion tree git
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y install https://yum.puppet.com/puppet6-release-el-8.noarch.rpm
dnf -y install puppetserver
/opt/puppetlabs/puppet/bin/gem install r10k
mkdir -p /etc/puppetlabs/r10k/
cat << EOF > /etc/puppetlabs/r10k/r10k.yaml
cachedir: '/var/cache/r10k'
sources:
  :teeth-puppet-controlrepo:
    remote: git@github.com:thirteen-teeth/control-repo.git
    basedir: '/etc/puppetlabs/code/environments'
EOF

/opt/puppetlabs/puppet/bin/r10k deploy environment -p -v

cat << EOF >> /etc/puppetlabs/puppet/puppet.conf

[master]
dns_alt_names = puppetserver,master.puppetdomain

[main]
server = master.puppetdomain
certname = master.puppetdomain
runinterval = 30m
EOF

cat << EOF > /etc/puppetlabs/puppet/autosign.conf
*.puppetdomain
EOF

systemctl start puppetserver
systemctl enable puppetserver

date > /tmp/vagrant_provisioned_at