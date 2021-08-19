#!/bin/bash
# https://rpmfind.net/linux/mageia/distrib/8/x86_64/media/core/release/xmessage-1.0.5-3.mga8.x86_64.rpm

start_time="$(date +%s)"

if [ -z "$1" ]; then
  my_role='default'
else
  my_role=$1
fi

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
dnf -y install vim bash-completion tree git setroubleshoot unzip
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y install https://yum.puppet.com/puppet6-release-el-8.noarch.rpm

#for puppetdb because puppetdb/postgresl class doesn't install the right repo
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql

#dnf -y install https://yum.theforeman.org/releases/2.4/el8/x86_64/foreman-release.rpm
#dnf -y install foreman-installer

# prepare DNS for foreman install
#sed -i '/127.0.1.1 master.puppetdomain master/d' /etc/hosts
#foreman-installer  

dnf -y install puppetserver

cat << EOF > /etc/puppetlabs/puppet/puppet.conf
[server]
vardir = /opt/puppetlabs/server/data/puppetserver
logdir = /var/log/puppetlabs/puppetserver
rundir = /var/run/puppetlabs/puppetserver
pidfile = /var/run/puppetlabs/puppetserver/puppetserver.pid
codedir = /etc/puppetlabs/code

[master]
dns_alt_names = puppetserver,${HOSTNAME}

[main]
server = ${HOSTNAME}
certname = ${HOSTNAME}
runinterval = 30m
EOF

cat << EOF > /etc/puppetlabs/puppet/csr_attributes.yaml
extension_requests:
  pp_role: ${my_role}
  pp_environment: development
EOF

# autosign agents in the puppetdomain domain
cat << EOF > /etc/puppetlabs/puppet/autosign.conf
*.puppetdomain
EOF

# maybe there is an oppurtunity to use docker with this and mount the basedir volume
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

systemctl start puppetserver
systemctl enable puppetserver

puppet agent -t

systemctl start puppet
systemctl enable puppet

end_time="$(($(date +%s)-$start_time))"
running_time=$(date -d $end_time +%H:%M:%S)
echo "Script completed in $running_time"
date > /tmp/vagrant_provisioned_at
