####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

apt::source { "mesosphere":
    location          => "http://repos.mesosphere.io/ubuntu",
    release           => "trusty",
    repos             => "main",
    key               => "E56151BF",
    key_server        => "keyserver.ubuntu.com",
    include_src       => false,
    include_deb       => true,
}

