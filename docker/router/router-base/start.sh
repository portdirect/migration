#!/bin/bash
set -e

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Setting up iptables"
echo "-------------------------------------------------------------------------"
iptables -t nat -A POSTROUTING -j MASQUERADE

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Waiting for pipework to give us the eth1 interface"
echo "-------------------------------------------------------------------------"
/pipework --wait

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Staring nload to give traffic overview"
echo "-------------------------------------------------------------------------"
/usr/bin/nload devices eth1
