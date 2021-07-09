# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 2.2.0"
VAGRANTFILE_API_VERSION = "2'"
require "yaml"
#servers = YAML.load_file('servers.yaml')

ol8_box_url = "https://yum.oracle.com/boxes/oraclelinux/ol8/OL8U4_x86_64-vagrant-virtualbox-b220.box"
ol8_box_name = "oraclelinux/8"

Vagrant.configure("2") do |config|
  config.vm.define "master" do |node|
    node.vm.box = "#{ol8_box_name}"
    node.vm.box_url = "#{ol8_box_url}"
    node.vm.hostname = "master.puppetdomain"
    node.vm.network "private_network", ip: "10.0.0.10"
    node.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 4
      end
    node.hostmanager.manage_guest = true
    node.vm.provision :hostmanager  
    node.vm.provision "file", source: "~/.ssh/id_rsa", destination: "/tmp/id_rsa"
    node.vm.provision "shell", path: "master-provision.sh"
    node.ssh.forward_agent = true
  end

  config.vm.define "kafka-host" do |node|
    node.vm.box = "#{ol8_box_name}"
    node.vm.box_url = "#{ol8_box_url}"
    node.vm.hostname = "kafka-host.puppetdomain"
    node.vm.network "private_network", ip: "10.0.0.11"
    node.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 4
    end
    node.hostmanager.manage_guest = true
    node.vm.provision :hostmanager
    node.vm.provision "shell", path: "agent-provision.sh"
  end

  config.vm.define "kafka-mirror" do |node|
    node.vm.box = "#{ol8_box_name}"
    node.vm.box_url = "#{ol8_box_url}"
    node.vm.hostname = "kafka-mirror.puppetdomain"
    node.vm.network "private_network", ip: "10.0.0.12"
    node.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 4
    end
    node.hostmanager.manage_guest = true
    node.vm.provision :hostmanager
    node.vm.provision "shell", path: "agent-provision.sh"
  end

  config.vm.define "kafka-target" do |node|
    node.vm.box = "#{ol8_box_name}"
    node.vm.box_url = "#{ol8_box_url}"
    node.vm.hostname = "kafka-target.puppetdomain"
    node.vm.network "private_network", ip: "10.0.0.13"
    node.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 4
    end
    node.hostmanager.manage_guest = true
    node.vm.provision :hostmanager
    node.vm.provision "shell", path: "agent-provision.sh"
  end

  config.vm.define "kafka-secondary" do |node|
    node.vm.box = "#{ol8_box_name}"
    node.vm.box_url = "#{ol8_box_url}"
    node.vm.hostname = "kafka-secondary.puppetdomain"
    node.vm.network "private_network", ip: "10.0.0.14"
    node.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 4
    end
    node.hostmanager.manage_guest = true
    node.vm.provision :hostmanager
    node.vm.provision "shell", path: "agent-provision.sh"
  end

end