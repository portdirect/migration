#!/bin/bash
set -e

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Sourcing PXE Config"
echo "-------------------------------------------------------------------------"
. /etc/pxe/pxe.env

: ${DHCP_SERVER_INTERFACE:=br0}
: ${DHCP_LEASE_TIME:=1h}
# Setting defaults

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Waiting For Pipework"
echo "-------------------------------------------------------------------------"
/bin/pipework --wait -i eth0

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Waiting For Setting the MTU"
echo "-------------------------------------------------------------------------"
MAX_MTU=$(ip -f inet -o link show eth0 |cut -d\  -f 5| cut -d/ -f 1)



echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Sourcing ETCD Config"
echo "-------------------------------------------------------------------------"
. /etc/etcd/etcd.conf
ETCD_DISCOVERY_TOKEN=$ETCD_DISCOVERY

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Sourcing SSH Public Key"
echo "-------------------------------------------------------------------------"
SSH_PUBLIC_KEY=$(echo $(cat /root/.ssh/id_rsa.pub))


SERVER_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Setting up iptables"
echo "-------------------------------------------------------------------------"

iptables -t nat -A POSTROUTING -j MASQUERADE




echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: This server: $SERVER_IP"
echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Repo Server: $REPO_IP"
echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Docker registry mirror: $DOCKER_REGISTRY_MIRROR_IP"
echo "-------------------------------------------------------------------------"



echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Update pxelinux config to point to the server ip"
echo "-------------------------------------------------------------------------"

sed -i "s/{{ SERVER_IP }}/$SERVER_IP/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/{{ SERVER_IP }}/$SERVER_IP/g" /usr/share/nginx/html/ks/*


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Updating kickstarts and pxelinux to point to repo server"
echo "-------------------------------------------------------------------------"

sed -i "s/{{ REPO_IP }}/$REPO_IP/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/{{ REPO_IP }}/$REPO_IP/g" /usr/share/nginx/html/ks/*



echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Updating kickstarts to point to docker registry mirror"
echo "-------------------------------------------------------------------------"
sed -i "s/{{ DOCKER_REGISTRY_MIRROR_IP }}/$DOCKER_REGISTRY_MIRROR_IP/g" /usr/share/nginx/html/ks/*


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Injecting ssh key into kickstarts"
echo "-------------------------------------------------------------------------"
SSH_PUBLIC_KEY_SAFE=$(echo $SSH_PUBLIC_KEY | sed "s,/,\\\/,g")
sed -i "s/{{ SSH_PUBLIC_KEY }}/$SSH_PUBLIC_KEY_SAFE/g" /usr/share/nginx/html/ks/*


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: ETCD discovery token: $ETCD_DISCOVERY_TOKEN"
echo "-------------------------------------------------------------------------"
sed -i "s,{{ ETCD_DISCOVERY_TOKEN }},$ETCD_DISCOVERY_TOKEN,g" /usr/share/nginx/html/ks/*

echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Domain: $DOMAIN"
echo "-------------------------------------------------------------------------"
sed -i "s,{{ DOMAIN }},$DOMAIN,g" /usr/share/nginx/html/ks/*


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Kubernetes: $DOMAIN"
echo "-------------------------------------------------------------------------"
sed -i "s,{{ KUBE_API_HOST }},$KUBE_API_HOST,g" /usr/share/nginx/html/ks/*


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Skydns: $DOMAIN"
echo "-------------------------------------------------------------------------"
sed -i "s,{{ SKYDNS_IP }},$SKYDNS_IP,g" /usr/share/nginx/html/ks/*



echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: DHCP INFO"
echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: DHCP INFO: DHCP_SERVER_INTERFACE: $DHCP_SERVER_INTERFACE"
echo "${OS_DISTRO}: DHCP INFO: DHCP_RANGE_START: $DHCP_RANGE_START"
echo "${OS_DISTRO}: DHCP INFO: DHCP_RANGE_END: $DHCP_RANGE_END"
echo "${OS_DISTRO}: DHCP INFO: DHCP_RANGE_SUBNETMASK: $DHCP_RANGE_SUBNETMASK"
echo "${OS_DISTRO}: DHCP INFO: DHCP_LEASE_TIME: $DHCP_LEASE_TIME"
echo "-------------------------------------------------------------------------"


echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Starting nginx"
echo "-------------------------------------------------------------------------"
nginx



echo "-------------------------------------------------------------------------"
echo "${OS_DISTRO}: Starting PXE server"
echo "-------------------------------------------------------------------------"
dnsmasq --interface=eth0 \
    --port=0 \
    --dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,$DHCP_RANGE_SUBNETMASK,$DHCP_LEASE_TIME \
    --dhcp-option=6,$SKYDNS_IP \
    --dhcp-option=3,$SERVER_IP \
    --dhcp-option=26,$MAX_MTU \
    --dhcp-boot=pxelinux.0,pxeserver,$SERVER_IP \
    --pxe-service=x86PC,"${OS_DISTRO}: Managed Boot",pxelinux \
    --enable-tftp \
    --tftp-root=/var/lib/tftpboot \
    --server=8.8.8.8 \
    --no-daemon
