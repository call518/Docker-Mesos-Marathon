####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

apt::source { "docker":
    location          => "http://get.docker.io/ubuntu",
    release           => "docker",
    repos             => "main",
    key               => "D8576A8BA88D21E9",
    include_src       => false,
    include_deb       => true,
    before            => Exec["Install lxc-docker"],
}

package { "python-pip":
    ensure   => installed,
}

package { "mesos":
    ensure   => installed,
}

exec { "Set Mesos-Slave Hostname":
    command => "echo $::hostname > /etc/mesos-slave/hostname",
    user     => "root",
    timeout  => "0",
    require => [Package["python-pip"], Package["mesos"]],
}

exec { "Set DNS Nameserver":
    command => "sed -i '1s/^/nameserver ${master_ip}\\n/' /etc/resolv.conf",
    user     => "root",
    timeout  => "0",
    unless => "grep -q ${master_ip} /etc/resolv.conf",
    require => Exec["Set Mesos-Slave Hostname"],
}

service { 'Stop Zookeeper Service':
    name => "zookeeper",
    ensure => stopped,
    enable => false,
    provider => "upstart",
    require => Exec["Set DNS Nameserver"],
}

service { 'Stop Mesos-Master Service':
    name => "mesos-master",
    ensure => stopped,
    enable => false,
    provider => "upstart",
    require => Service["Stop Zookeeper Service"],
}

exec { "Install lxc-docker":
    command => "apt-get -q -y --force-yes -o DPkg::Options::=--force-confold install lxc-docker",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => Service["Stop Mesos-Master Service"],
}

file { "Config /etc/default/docker":
    path    => "/etc/default/docker",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/etc_default_docker.erb"),
    require => Exec["Install lxc-docker"],
}
        
exec { "Set /etc/mesos/zk":
    command => "echo 'zk://master:2181/mesos' > /etc/mesos/zk",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => File["Config /etc/default/docker"],
}

if $::use_deimos == false {
    exec { "Install Deimos":
        command => "pip install deimos",
        user     => "root",
        timeout  => "0",
        logoutput => true,
        require => Exec["Set /etc/mesos/zk"],
    }
    
    file { "Set deimos.cfg":
        path    => "/etc/deimos.cfg",
        ensure  => present,
        owner   => "root",
        group   => "root",
        mode    => 0755,
        content => template("/vagrant/resources/puppet/templates/deimos.cfg.erb"),
        require => Exec["Install Deimos"],
    }
        
    exec { "Set /etc/mesos-slave/containerizer_path":
        command => "echo /usr/local/bin/deimos > /etc/mesos-slave/containerizer_path",
        user     => "root",
        timeout  => "0",
        logoutput => true,
        require => File["Set deimos.cfg"],
    }
    
    exec { "Set /etc/mesos-slave/containerizers":
        command => "echo external > /etc/mesos-slave/containerizers",
        user     => "root",
        timeout  => "0",
        logoutput => true,
        require => Exec["Set /etc/mesos-slave/containerizer_path"],
    }
} else {
    exec { "Set /etc/mesos-slave/executor_registration_timeout":
        command => "echo '5mins' > /etc/mesos-slave/executor_registration_timeout",
        user     => "root",
        timeout  => "0",
        logoutput => true,
        require => Exec["Set /etc/mesos/zk"],
    }

    exec { "Set /etc/mesos-slave/containerizers":
        command => "echo 'docker,mesos' > /etc/mesos-slave/containerizers",
        user     => "root",
        timeout  => "0",
        logoutput => true,
        require => Exec["Set /etc/mesos-slave/executor_registration_timeout"],
    }
}

exec { "Reload Configuration":
    command => "initctl reload-configuration",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => Exec["Set /etc/mesos-slave/containerizers"],
}

service { "docker":
    ensure => running,
    require => Exec["Reload Configuration"],
}

service { "mesos-slave":
    ensure => running,
    provider => "upstart",
    subscribe => [Exec["Set /etc/mesos/zk"], Exec["Set /etc/mesos-slave/containerizers"], Exec["Set /etc/mesos-slave/executor_registration_timeout"]],
    require => Service["docker"],
}

exec { "Restart All Services":
    command => "service docker stop; service docker start; service mesos-slave stop; service mesos-slave start",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => Service["mesos-slave"],
}

exec { "Install Weave Script":
    command => "wget https://github.com/zettio/weave/releases/download/latest_release/weave -O /usr/local/bin/weave && chmod a+x /usr/local/bin/weave",
    user     => "root",
    timeout  => "0",
    require => Exec["Restart All Services"],
}

exec { "Reset Weave":
    command => "/usr/local/bin/weave reset",
    user     => "root",
    timeout  => "0",
    require => Exec["Install Weave Script"],
}

#exec { "Start DNSDock":
#    provider => shell,
#    command => "if docker ps -a -f name=dnsdock | grep dnsdock; then docker rm -f dnsdock 2> /dev/null > /dev/null; fi; docker run -d -v /var/run/docker.sock:/var/run/docker.sock --name dnsdock -p $::docker_bip:53:53/udp tonistiigi/dnsdock --domain=$::dnsdock_domain --environment=$::dnsdock_environment",
#    user     => "root",
#    timeout  => "0",
#    #logoutput => true,
#    unless => "docker ps -a -f name=dnsdock -f status=running | grep -q dnsdock",
#    require => Exec["Restart All Services"],
#}
