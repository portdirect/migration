#!/bin/bash
set -e

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Waiting For Pipework"
echo "-------------------------------------------------------------------------"
pipework --wait -i eth1

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Setting up iptables"
echo "-------------------------------------------------------------------------"
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Tailing /dev/null"
echo "-------------------------------------------------------------------------"
tail -f /dev/null
