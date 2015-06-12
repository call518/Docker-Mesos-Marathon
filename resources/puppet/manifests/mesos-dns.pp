####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

#package { "golang":
#    ensure   => installed,
#}

#package { "python-setuptools":
#    ensure   => installed,
#}

#package { "software-properties-common":
#    ensure   => installed,
#}

$go_ver = "1.4.2"
$go_tar = "go${go_ver}.linux-amd64.tar.gz"

$GOPATH = "/home/go"
$GOROOT = "/usr/local/go"

$go_env_file = "/etc/profile.d/go-env.sh"
$mesos_dns_dir = "/usr/local/mesos-dns"

exec { "Download ${go_tar}":
    command => "wget -q https://storage.googleapis.com/golang/${go_tar} -O /usr/local/src/${go_tar}",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "test -f /usr/local/src/${go_tar}",
}

exec { "Extract ${go_tar}":
    command => "tar zxf /usr/local/src/${go_tar} -C /usr/local",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless   => "test -d ${GOROOT}",
    require => Exec["Download ${go_tar}"],
}

######### Setup Mesos-DNS ##########

file { "${go_env_file}":
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode     => 0644,
    content => template("/vagrant/resources/puppet/templates/go-env.sh.erb"),
    require  => Exec["Extract ${go_tar}"],
}

file { "${GOPATH}":
    ensure   => directory,
    owner    => "root",
    group    => "root",
    mode     => 0750,
    require => File["${go_env_file}"],
}

file { "/usr/local/src/install-mesos-dns.sh":
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode     => 0755,
    content => template("/vagrant/resources/puppet/templates/install-mesos-dns.sh.erb"),
    require  => Exec["Extract ${go_tar}"],
}

exec { "Install mesos-dns":
    provider => shell,
    command => "/usr/local/src/install-mesos-dns.sh",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    unless  => "test -f ${mesos_dns_dir}/mesos-dns",
    require => File["/usr/local/src/install-mesos-dns.sh"],
}

file { "${mesos_dns_dir}":
    ensure   => directory,
    owner    => "root",
    group    => "root",
    mode     => 0750,
    require  => Exec["Install mesos-dns"],
}

file { "${mesos_dns_dir}/mesos-dns":
    ensure   => link,
    target   => "${GOPATH}/bin/mesos-dns",
    owner    => "root",
    group    => "root",
    replace  => true,
    require  => File["${mesos_dns_dir}"],
}

file { "Config Mesos-DNS":
    path    => "${mesos_dns_dir}/config.json",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/mesos-dns-config.json.erb"),
    require => File["${mesos_dns_dir}/mesos-dns"],
}
        
exec { "Run Mesos-DNS Service":
    provider => shell,
    command => "${mesos_dns_dir}/mesos-dns -config=${mesos_dns_dir}/config.json &",
    #environment => ["GOPATH=${GOPATH}", "PATH=\${PATH}:${GOPATH}/bin", "GOROOT=${GOROOT}", "PATH=\${PATH}:${GOROOT}/bin"],
    user     => "root",
    timeout  => "0",
    #logoutput => true,
    unless   => "lsof -ni:#{mesos_dns_conf_port}",
    require => File["Config Mesos-DNS"],
}

exec { "Set DNS Nameserver":
    command => "sed -i '1s/^/nameserver 127.0.0.1\\n/' /etc/resolv.conf",
    user     => "root",
    timeout  => "0",
    require => Exec["Run Mesos-DNS Service"],
}

