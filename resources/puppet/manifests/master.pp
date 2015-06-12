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

#package { "python-setuptools":
#    ensure   => installed,
#}

package { "git":
    ensure   => installed,
}

package { "python-setuptools":
    ensure   => installed,
}

package { "mesosphere":
    ensure   => installed,
}

exec { "Set ZK's myid":
    command  => "echo ${zk_myid} > /etc/zookeeper/conf/myid",
    user     => "root",
    timeout  => "0",
    require => [Package["git"], Package["python-setuptools"], Package["mesosphere"]],
}

exec { "Set Mesos-Master Hostname":
    command => "echo $::hostname > /etc/mesos-master/hostname",
    user     => "root",
    timeout  => "0",
    require => Exec["Set ZK's myid"],
}

exec { "Set Marathon Hostname (1)":
    command => "mkdir -p /etc/marathon/conf",
    user     => "root",
    timeout  => "0",
    require => Exec["Set Mesos-Master Hostname"],
}

exec { "Set Marathon Hostname (2)":
    command => "echo $::hostname > /etc/marathon/conf/hostname",
    user     => "root",
    timeout  => "0",
    require => Exec["Set Marathon Hostname (1)"],
}

exec { "Set Mesos's Registry":
    command => "echo in_memory > /etc/mesos-master/registry",
    user     => "root",
    timeout  => "0",
    require => Exec["Set Marathon Hostname (2)"],
}

$mesos_egg_file = "mesos-0.19.0_rc2-py2.7-linux-x86_64.egg"

exec { "Download Mesos Egg":
    command => "wget http://downloads.mesosphere.io/master/ubuntu/14.04/${mesos_egg_file} -O /usr/local/src/${mesos_egg_file}",
    user     => "root",
    timeout  => "0",
    #logoutput => true,
    onlyif   => "test ! -f /usr/local/src/${mesos_egg_file}",
    require => Exec["Set Mesos's Registry"],
}

exec { "Install Mesos Egg":
    command => "easy_install /usr/local/src/${mesos_egg_file}",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => Exec["Download Mesos Egg"],
}

service { 'Stop Mesos-Slave Service':
    name => "mesos-slave",
    ensure => stopped,
    enable => false,
    provider => "upstart",
    require => Exec["Install Mesos Egg"],
}

exec { "Install lxc-docker":
    command => "apt-get -q -y --force-yes -o DPkg::Options::=--force-confold install lxc-docker",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => Service["Stop Mesos-Slave Service"],
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
        
exec { "Reload Configuration":
    command => "initctl reload-configuration",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => File["Config /etc/default/docker"],
}

service { "zookeeper":
    ensure => running,
    provider => "upstart",
    subscribe => Exec["Set ZK's myid"],
    require => Exec["Reload Configuration"],
}

service { "mesos-master":
    ensure => running,
    provider => "upstart",
    subscribe => [Exec["Set Mesos's Registry"], Exec["Install Mesos Egg"]],
    require => Service["zookeeper"],
}

service { "marathon":
    ensure => running,
    provider => "upstart",
    require => Service["mesos-master"],
}

exec { "Restart All Services":
    command => "service zookeeper stop; service zookeeper start; service mesos-master stop; service mesos-master start; service marathon stop; service marathon start",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => Service["marathon"],
}

if $::chronos == "true" {
    service { "chronos":
        ensure => running,
        require => Exec["Restart All Services"],
    }
    exec { "Restart Chronos Services":
        command => "service chronos stop; service chronos start",
        require => Service["chronos"],
        user     => "root",
        timeout  => "0",
        logoutput => true,
        require => Service["chronos"],
    }
}

