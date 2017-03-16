#!/bin/sh

#Colours
red="\033[00;31m"
RED="\033[01;31m"

green="\033[00;32m"
GREEN="\033[01;32m"

brown="\033[00;33m"
YELLOW="\033[01;33m"

blue="\033[00;34m"
BLUE="\033[01;34m"

purple="\033[00;35m"
PURPLE="\033[01;35m"

cyan="\033[00;36m"
CYAN="\033[01;36m"

white="\033[00;37m"
WHITE="\033[01;37m"

NC="\033[00m"

CPUMOD=$(cat /proc/cpuinfo | grep -m 1 -w 'model name' | awk -F: '{print $2}')
HOSTNAME=$(uname -n)
KERNEL=$(uname -r)
MEMTOTAL=$(cat /proc/meminfo | grep -m 1 -w 'MemTotal' | awk -F: '{print $2}')
MEMFREE=$(cat /proc/meminfo | grep -m 1 -w 'MemFree' | awk -F: '{print $2}')
SWAPTOTAL=$(cat /proc/meminfo | grep -m 1 -w 'SwapTotal' | awk -F: '{print $2}')
SWAPFREE=$(cat /proc/meminfo | grep -m 1 -w 'SwapFree' | awk -F: '{print $2}')
IPADDRESS=$(ip addr show | grep -v 127.0.0.1 | grep "inet " | cut -d" " -f6)
GATEWAY=$(/sbin/ip route | awk '/default/ { print $3 }')

echo -e "${RED}******************************************************************************"
echo -e "${WHITE} Hostname:   ${HOSTNAME}"
echo -e "${WHITE} Date: "`date`
echo -e ""
echo -e "${CYAN} IP Address: ${IPADDRESS}"
echo -e "${CYAN} Gateway: ${GATEWAY}"
echo -e ""
echo -e "${WHITE} Total Memory: ${MEMTOTAL}"
echo -e "${WHITE} Free Memory: ${MEMFREE}"
echo -e ""
echo -e "${WHITE} Swap Total:    ${SWAPTOTAL}"
echo -e "${WHITE} Swap Free:    ${SWAPFREE}"
echo -e ""
echo -e "${RED}******************************************************************************"

if [ ! -f /opt/Provisioning/.done ]; then
echo -e "${YELLOW}Please run the follwing command to configure this system for the first time:"
echo -e "${YELLOW} => sh /opt/Provisioning/rhel7/init.sh"
fi

# Reset Terminal Colour Back to Normal
echo -e "${NC}"
