et root password with passwd and run as root

# Set timezone
defaultTZ=Atlantic/Reykjavik
read -p "Enter Time Zone [$defaultTZ]: " TZ
TZ=${TZ:-$defaultTZ}
timedatectl set-timezone $TZ

# Set Static IP Info - only runs once
if [ ! -f /etc/sysconfig/network-scripts/ifcfg-rhel7 ]; then
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
defaultHost=rhel7.local
read -p "Enter Hostname [$defaultHost]: " HOSTNAME
HOSTNAME=${HOSTNAME:-$defaultHost}
hostnamectl set-hostname $HOSTNAME --static

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
if $str($getVar('puppet_auto_setup','')) == "1"
# Add puppet master to puppet.conf
sed -i '/\[agent\]/ a\    server = puppetmaster' /etc/puppet/puppet.conf
# Restart Puppet agent
systemctl restart puppet
# generate puppet certificates and trigger a signing request, but
# don't wait for signing to complete (in seconds)
/usr/sbin/puppetd --test --waitforcert 0
# turn puppet service on for reboot
systemctl enable puppet
