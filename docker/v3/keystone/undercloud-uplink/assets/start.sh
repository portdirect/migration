#!/bin/sh
set -e
echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Determining container uplink device"
echo "-------------------------------------------------------------------------"
UPLINK_DEV_CONTAINER="$(ip route | grep ${UPLINK_IP_RANGE} | awk '{ print $3 }')"
echo "${OS_DISTRO}: We are connected to the uplink network via ${UPLINK_DEV_CONTAINER}"


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Setting up routing"
echo "-------------------------------------------------------------------------"
ip route add ${PUBLIC_IP_RANGE} via ${UPLINK_GATEWAY}


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Setting up iptables"
echo "-------------------------------------------------------------------------"
iptables -A FORWARD -i ${UPLINK_DEV_CONTAINER} -o eth0 -j ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Going to sleep"
echo "-------------------------------------------------------------------------"
exec tail -f /dev/null
