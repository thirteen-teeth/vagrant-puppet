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

Clone this repo

```vagrant up```

> **WARNING**: This Vagrantfile will copy the user's ~/.ssh/id_rsa to the Puppet master VM to be used in r10k