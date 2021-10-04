# -*- mode: ruby -*-
# # vi: set ft=ruby :
# https://blog.scottlowe.org/2016/01/14/improved-way-yaml-vagrant/

if not Vagrant.has_plugin?('vagrant-hostmanager')
  abort <<-EOM

please run the following command to install the vagrant-hostmanager plugin:
vagrant plugin install vagrant-hostmanager

  EOM
end

Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"

require 'yaml'
load_servers = YAML.load_file(File.join(File.dirname(__FILE__), 'servers.yaml'))

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  load_servers.each do |servers|
    config.vm.define servers['name'] do |srv|
      srv.vm.box = servers['box']
      srv.vm.network "private_network", ip: servers['ip']
      srv.vm.hostname = "#{servers['name']}.puppetdomain"
      srv.vm.provider :virtualbox do |vb|
        vb.memory = servers['ram']
        vb.cpus = servers['cpus']
      end
      if servers['forward_ports']
        servers['forward_ports'].each do |port|
          srv.vm.network "forwarded_port", guest: port, host: port
        end
      end
      srv.hostmanager.manage_guest = true
      srv.vm.provision :hostmanager
      if servers['script'] == 'master-provision.sh'
        srv.vm.provision "file", source: "~/.ssh/id_rsa", destination: "/tmp/id_rsa"
      end
      srv.vm.synced_folder "vault_data/", "/opt/vault_data"
      srv.vm.provision "shell", path: servers['script'], args: servers['role']
    end
  end
end
