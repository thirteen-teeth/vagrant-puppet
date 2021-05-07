# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "master" do |node|
    node.vm.box = "ol8"
    node.vm.box_url = "https://yum.oracle.com/boxes/oraclelinux/ol80/ol80.box"
    node.vm.hostname = "master.puppetdomain"
    node.vm.network "private_network", ip: "10.0.0.10"
    node.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 4
      end
    node.vm.provision "file", source: "~/.ssh/id_rsa", destination: "/tmp/id_rsa"
    node.vm.provision "shell", path: "master-provision.sh"
    node.ssh.forward_agent = true
    node.vm.provision "hosts", sync_hosts: true
  end

  config.vm.define "agent" do |node|
    node.vm.box = "ol8"
    node.vm.box_url = "https://yum.oracle.com/boxes/oraclelinux/ol80/ol80.box"
    node.vm.hostname = "agent.puppetdomain"
    node.vm.network "private_network", ip: "10.0.0.11"
    node.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 4
    end
    node.vm.provision "shell", path: "agent-provision.sh"
    node.vm.provision "hosts", sync_hosts: true
  end

end