#!/bin/sh

#
# Variables to change
#

defaultTZ=Atlantic/Reykjavik
# RedHat Subscription Manager
rhn_subscription_user=username@domain.com
rhn_subscription_password=PassWord
# Network configuration
network_device_name=eth0
network_connection_name=RHEL7
defaultDNS1=8.8.8.8
defaultDNS2=8.8.8.8
# Puppet Configuration
puppetmaster=puppetmaster

# Do not change anything below

# Set timezone
read -p "Enter Time Zone [$defaultTZ]: " TZ
TZ=${TZ:-$defaultTZ}
timedatectl set-timezone "$TZ"

# Set Static IP Info - only runs once
if [ ! -f /etc/sysconfig/network-scripts/ifcfg-$network_connection_name ]; then
        defaultIP=$(ip addr show dev $network_device_name | grep "inet " | cut -d" " -f6)
        defaultGW=$(/sbin/ip route | awk '/default/ { print $3 }')
	read -p "Enter Static IP Address and CIDR [$defaultIP]: " IPADDR
	read -p "ENTER GATEWAY [$defaultGW]: " GATEWAY
	read -p "Enter DNS1 [$defaultDNS1]: " DNS1
	read -p "Enter DNS2 [$defaultDNS2]: " DNS2
	IPADDR=${IPADDR:-$defaultIP}
	GATEWAY=${GATEWAY:-$defaultGW}
	DNS1=${DNS1:-$defaultDNS1}
	DNS2=${DNS2:-$defaultDNS2}
	{ nmcli connection add type ethernet con-name $network_connection_name ifname $network_device_name ip4 $IPADDR gw4 $GATEWAY &&
	  nmcli connection modify $network_connection_name ipv4.dns "$DNS1 $DNS2" &&
	  nmcli connection up $network_connection_name ifname $network_device_name &&
	  nmcli -p connection show $network_connection_name ;
	} || {
	  echo "Failed to set IP Address" && exit ;
	}
fi

# Set hostname
defaultHost=$HOSTNAME
read -p "Enter Hostname [$defaultHost]: " HOSTNAME
HOSTNAME=${HOSTNAME:-$defaultHost}
hostnamectl set-hostname $HOSTNAME --static

# Register system
subscription-manager register --username=$rhn_subscription_user --password=$rhn_subscription_password --auto-attach
subscription-manager repos --enable=rhel-7-server-extras-rpms
subscription-manager repos --enable=rhel-7-server-extras-rpms
subscription-manager repos --enable=rhel-7-server-optional-rpms
subscription-manager repos --enable=rhel-7-server-optional-rpms

# Update all packages
yum update -y && yum -y upgrade

# Install epel-release
yum install -y epel-release

# Install some great tools
yum install -y nmap sed git

# Disable root ssh login
# sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
# systemctl restart sshd.service

# Install Puppet
### Install Puppet Agent ###
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
yum -t -y -e 0 install puppet
# Add puppet master to puppet.conf
sed -i '/\[agent\]/ a\    server = '"$puppetmaster"'' /etc/puppet/puppet.conf
# Restart Puppet agent
systemctl restart puppet
# generate puppet certificates and trigger a signing request
puppet agent -tv
# turn puppet service on for reboot
systemctl enable puppet
