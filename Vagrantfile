# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  #config.vm.boot_timeout = 600
  #config.vm.provider :virtualbox do |vb|
  #  vb.gui = true
  #end
  #config.ssh.forward_x11 = true

  master_ip = "192.168.10.11"
  use_deimos = "false"
  use_mesos_dns = "true"
  use_chronos = "false"
  docker_bip = "172.17.42.1"
  mesos_dns_conf_ttl = "60"
  mesos_dns_conf_port = "53"
  mesos_dns_conf_domain = "mesos"
  use_weave = "false"

  config.vm.box = "trusty64"
  config.vm.box_url = "https://onedrive.live.com/download?resid=28f8f701dc29e4b9%21247"

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "#{master_ip}"
    master.vm.network "forwarded_port", guest: 8080, host: 8080
    master.vm.network "forwarded_port", guest: 5050, host: 5050
    master.vm.network "forwarded_port", guest: 4400, host: 4400
    master.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--cpus", "2"]
      vb.customize ["modifyvm", :id, "--memory", "2048"]
    end
    master.vm.provision "shell", path: "resources/puppet/scripts/upgrade-puppet.sh"
    master.vm.provision "shell", path: "resources/puppet/scripts/bootstrap.sh"
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "base.pp"
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "common.pp"
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "master.pp"
      puppet.facter = {
        "master_ip" => "#{master_ip}",
        "zk_myid" => "1",
        "use_chronos" => "#{use_chronos}",
      }
      puppet.options = "--verbose"
    end
    if use_mesos_dns == "true"
      master.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "mesos-dns.pp"
        puppet.facter = {
          "master_ip" => "#{master_ip}",
          "use_mesos_dns" => "#{use_mesos_dns}",
          "mesos_dns_conf_domain" => "#{mesos_dns_conf_domain}",
          "mesos_dns_conf_port" => "#{mesos_dns_conf_port}",
          "mesos_dns_conf_ttl" => "#{mesos_dns_conf_ttl}",
        }
        puppet.options = "--verbose"
      end
    end
    if use_weave == "true"
      master.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "weave.pp"
        puppet.options = "--verbose"
      end
    end
  end

  num_slave_nodes = 2 ## (WARNING) Sync with hiera file -> "resources/puppet/hieradata/hosts.json"
  slave_ip_base = "192.168.10."
  slave_ips = num_slave_nodes.times.collect { |n| slave_ip_base + "#{n+51}" }
  
  num_slave_nodes.times do |n|
    config.vm.define "slave-#{n+1}" do |slave|
      slave_ip = slave_ips[n]
      slave.vm.hostname = "slave-#{n+1}"
      slave.vm.network "private_network", ip: "#{slave_ip}"
      slave.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--cpus", "2"]
        vb.customize ["modifyvm", :id, "--memory", "2048"]
      end
      slave.vm.provision "shell", path: "resources/puppet/scripts/upgrade-puppet.sh"
      slave.vm.provision "shell", path: "resources/puppet/scripts/bootstrap.sh"
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "base.pp"
        puppet.options = "--verbose"
      end
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "common.pp"
        puppet.options = "--verbose"
      end
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "slave.pp"
        puppet.facter = {
          "master_ip" => "#{master_ip}",
          "use_deimos" => "#{use_deimos}",
#(Not used)#          "dnsdock_domain" => "docker",
#(Not used)#          "dnsdock_environment" => "dev",
          "docker_bip" => "#{docker_bip}",
          "use_mesos_dns" => "#{use_mesos_dns}",
        }
        puppet.options = "--verbose"
      end
      if use_weave == "true"
        slave.vm.provision "puppet" do |puppet|
          puppet.working_directory = "/vagrant/resources/puppet"
          puppet.hiera_config_path = "resources/puppet/hiera.yaml"
          puppet.manifests_path = "resources/puppet/manifests"
          puppet.manifest_file  = "weave.pp"
          puppet.options = "--verbose"
        end
      end
    end
  end
end
