#!/bin/bash

if ! which puppet > /dev/null 2>&1 || [ `puppet -V | cut -d. -f1` -le 2 ]; then 
	apt-get update
	apt-get install --yes lsb-release
	DISTRIB_CODENAME=$(lsb_release --codename --short)
	DEB="puppetlabs-release-${DISTRIB_CODENAME}.deb"
	DEB_PROVIDES="/etc/apt/sources.list.d/puppetlabs.list" # Assume that this file's existence means we have the Puppet Labs repo added

	if [ ! -e $DEB_PROVIDES ]; then
		# Print statement useful for debugging, but automated runs of this will interpret any output as an error
		# print "Could not find $DEB_PROVIDES - fetching and installing $DEB"
		wget -q http://apt.puppetlabs.com/$DEB
		dpkg -i $DEB
	fi

	apt-get update
	apt-get install --yes puppet
	sed -i 's/^templatedir=/#templatedir=/g' /etc/puppet/puppet.conf
	puppet resource package puppet ensure=latest
fi
