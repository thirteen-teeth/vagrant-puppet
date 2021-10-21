# vagrant-puppet

Is a Vagrantfile and provisioning scripts to aid local testing of Puppet control repo's

## Prerequisites

This README assumes the user is using macOS

```bash
brew install virtualbox vagrant
brew install --cask virtualbox-extension-pack
vagrant plugin install vagrant-hostmanager 
```
https://github.com/devopsgroup-io/vagrant-hostmanager is used to enable DNS for any hosts in the Vagrantfile

## Usage

First create an custom opensearch vagrant box, to avoid downloading the opensearch tarball on each iteration
```

./build/build.sh

# build.sh will download the latest oraclelinux/8 box image from Oracle's website and
# download the specified version of Opensearch as a tarball to the /opt directory.
# then start vagrant and make yourself some tea while you wait
# if you wish to skip this step for whatever reason, edit servers.yaml to use the oraclelinux/8 box

vagrant up
```

> **WARNING**: This Vagrantfile will copy the user's ~/.ssh/id_rsa to the Puppet master VM to be used in r10k

## Opensearch cluster initialization

```
# ssh into any opensearch master server
vagrant ssh os-master-01

# review the opensearch service state, it should have repeat entries similar to the following
Oct 21 19:48:07 os-master-01.puppetdomain opensearch[8232]: [2021-10-21T19:48:07,023][ERROR][o.o.s.c.ConfigurationLoaderSecurity7] [os-master-01.puppetdomain] Failure no such index [.opendistro_security] retrieving configuration for [INTERNALUSERS, ACTIONGROUPS, CONFIG, ROLES, >

# run securityadmin.sh with the specified options to create the security indicies

export OPENSEARCH_DIR=/opt/opensearch-1.1.0
export JAVA_HOME=$OPENSEARCH_DIR/jdk
chmod +x $OPENSEARCH_DIR/plugins/opensearch-security/tools/securityadmin.sh
$OPENSEARCH_DIR/plugins/opensearch-security/tools/securityadmin.sh \
  -cd $OPENSEARCH_DIR/plugins/opensearch-security/securityconfig/ -icl -nhnv \
  -cacert $OPENSEARCH_DIR/config/ca.pem \
  -cert $OPENSEARCH_DIR/config/riker.pem \
  -key $OPENSEARCH_DIR/config/riker_private.pem

# output should be similar to the following

Security Admin v7
Will connect to localhost:9300 ... done
Connected as CN=riker
OpenSearch Version: 1.1.0
OpenSearch Security Version: 1.1.0.0
Contacting opensearch cluster 'opensearch' and wait for YELLOW clusterstate ...
Clustername: vagrant
Clusterstate: GREEN
Number of nodes: 3
Number of data nodes: 3
.opendistro_security index does not exists, attempt to create it ... done (0-all replicas)
Populate config from /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/
Will update '_doc/config' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/config.yml
   SUCC: Configuration for 'config' created or updated
Will update '_doc/roles' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/roles.yml
   SUCC: Configuration for 'roles' created or updated
Will update '_doc/rolesmapping' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/roles_mapping.yml
   SUCC: Configuration for 'rolesmapping' created or updated
Will update '_doc/internalusers' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/internal_users.yml
   SUCC: Configuration for 'internalusers' created or updated
Will update '_doc/actiongroups' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/action_groups.yml
   SUCC: Configuration for 'actiongroups' created or updated
Will update '_doc/tenants' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/tenants.yml
   SUCC: Configuration for 'tenants' created or updated
Will update '_doc/nodesdn' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/nodes_dn.yml
   SUCC: Configuration for 'nodesdn' created or updated
Will update '_doc/whitelist' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/whitelist.yml
   SUCC: Configuration for 'whitelist' created or updated
Will update '_doc/audit' with /opt/opensearch-1.1.0/plugins/opensearch-security/securityconfig/audit.yml
   SUCC: Configuration for 'audit' created or updated
Done with success

# step 4: ???
# step 5: profit
```