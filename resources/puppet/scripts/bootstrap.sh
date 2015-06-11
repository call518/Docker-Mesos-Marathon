#!/usr/bin/env bash
#
# This bootstraps Puppet on Ubuntu 12.04 LTS.
#
set -e

## Disabled Chef-Client
update-rc.d chef-client disable 2>&1 > /dev/null
service chef-client stop 2>&1 > /dev/null

## Installing Puppet Modules
#puppet module install puppetlabs-vcsrepo
#puppet module install puppetlabs-stdlib
#puppet module install puppetlabs-apt
puppet module install --force /vagrant/resources/puppet/files/puppetlabs-vcsrepo-1.1.0.tar.gz --ignore-dependencies
puppet module install --force /vagrant/resources/puppet/files/puppetlabs-stdlib-4.3.2.tar.gz --ignore-dependencies
puppet module install --force /vagrant/resources/puppet/files/puppetlabs-apt-1.6.0.tar.gz --ignore-dependencies

### Edit Apt-Repo. Address
if test ! -f /etc/apt/sources.list.vagrant-bak; then
  cp -a /etc/apt/sources.list /etc/apt/sources.list.vagrant-bak
fi
sed -i 's/kr\.archive\.ubuntu\.com/ftp\.daum\.net/g' /etc/apt/sources.list 2> /dev/null
sed -i 's/us\.archive\.ubuntu\.com/ftp\.daum\.net/g' /etc/apt/sources.list 2> /dev/null
sed -i 's/archive\.ubuntu\.com/ftp\.daum\.net/g' /etc/apt/sources.list 2> /dev/null
sed -i 's/security\.ubuntu\.com/ftp\.daum\.net/g' /etc/apt/sources.list 2> /dev/null
sed -i 's/extras\.ubuntu\.com/ftp\.daum\.net/g' /etc/apt/sources.list 2> /dev/null

#apt-get update
