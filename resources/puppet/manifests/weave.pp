####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

exec { "Install Weave Script":
    command => "wget https://github.com/zettio/weave/releases/download/latest_release/weave -O /usr/local/bin/weave && chmod a+x /usr/local/bin/weave",
    user     => "root",
    timeout  => "0",
}

exec { "Reset Weave":
    command => "/usr/local/bin/weave reset",
    user     => "root",
    timeout  => "0",
    require => Exec["Install Weave Script"],
}

