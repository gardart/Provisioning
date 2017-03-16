#!/bin/bash

# Set root password with passwd and run as root

# Set timezone
defaultTZ=America/New_York
read -p "Enter Time Zone [$defaultTZ]: " TZ
TZ=${TZ:-$defaultTZ}
timedatectl set-timezone $TZ

# Set Static IP Info - only runs once
if [ ! -f /etc/sysconfig/network-scripts/ifcfg-CentOS7 ]; then
	defaultIP=192.168.1.100/24
	defaultGW=192.168.1.1
	defaultDNS1=192.168.1.1
	defaultDNS2=8.8.8.8
	read -p "Enter Static IP Address and CIDR [$defaultIP]: " IPADDR
	read -p "ENTER GATEWAY [$defaultGW]: " GATEWAY
	read -p "Enter DNS1 [$defaultDNS1]: " DNS1
	read -p "Enter DNS2 [$defaultDNS2]: " DNS2
	IPADDR=${IPADDR:-$defaultIP}
	GATEWAY=${GATEWAY:-$defaultGW}
	DNS1=${DNS1:-$defaultDNS1}
	DNS2=${DNS2:-$defaultDNS2}
	{ nmcli connection add type ethernet con-name CentOS7 ifname eno16777736 ip4 $IPADDR gw4 $GATEWAY &&
	  nmcli connection modify CentOS7 ipv4.dns "$DNS1 $DNS2" &&
	  nmcli connection up CentOS7 ifname eno16777736 &&
	  nmcli -p connection show CentOS7 ;
	} || {
	  echo "Failed to set IP Address" && exit ;
	}
fi

# Set hostname
defaultHost=centos7-docker.local
read -p "Enter Hostname [$defaultHost]: " HOSTNAME
HOSTNAME=${HOSTNAME:-$defaultHost}
hostnamectl set-hostname $HOSTNAME --static

# Update all packages
yum update -y && yum -y upgrade

# Install epel-release
yum install -y epel-release

# Install nmap for network monitoring - check open ports via nmap localhost
yum install -y nmap

# Disable root ssh login
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd.service

# Install Fail2Ban
yum install -y fail2ban
systemctl enable fail2ban

# Configure Fail2Ban - if jail.local exists remove it and replace it
if [ -f /etc/fail2ban/jail.local ]; then
	rm /etc/fail2ban/jail.local
fi

touch /etc/fail2ban/jail.local
tee /etc/fail2ban/jail.local <<-'EOF'
[DEFAULT]
# Ban hosts for 10 minutes:
bantime = 600
# Ignore connections from localhost:
ignoreip = 127.0.0.1/8
# Grant 3 retries per 10 minutes:
findtime = 600
maxretry = 3
# Override /etc/fail2ban/jail.d/00-firewalld.conf:
banaction = iptables-multiport
[sshd]
enabled = true
EOF

# Restart Fail2Ban and display status
systemctl restart fail2ban
fail2ban-client status sshd

# Unban IP Address
# fail2ban-client set sshd unbanip IPADDRESS

# Install Docker Engine
if ! docker -v ; then
	curl -fsSL https://get.docker.com/ | sh
fi

# Start docker service if not running
if ps ax | grep -v grep | grep /usr/bin/docker; then
	docker run hello-world
else
	service docker start
fi

# Start docker on boot
chkconfig docker on

# Install Docker Compose v1.7.0
if [ ! -f /usr/local/bin/docker-compose ]; then
	curl -L https://github.com/docker/compose/releases/download/1.7.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
fi
