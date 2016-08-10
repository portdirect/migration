#!/bin/bash
set -e
# Default settings
: ${OVS_NETWORK:="10.96.0.0/12"}
: ${OVS_NETWORK_CIDR:="12"}
: ${OVS_DEV:="br0"}
: ${OVS_DOCKER_CIDR:="24"}

: ${DOCKER_BRIDGE_NAME:="docker0"}
: ${OVS_BRIDGE_NAME:="docker0_ovs"}
: ${OVS_CONTAINER_NAME:="ovs"}
: ${DOCKER_COMMAND:="docker"}
: ${OVS_TUNNEL_TYPE:="gre"}


OVS_CIDR=${OVS_NETWORK#*/}
OVS_NETWORK_START=${OVS_NETWORK%/*}
OVS_IP=$(ip -f inet -o addr show $OVS_DEV|cut -d\  -f 7 | cut -d/ -f 1)
HOSTNAME=$(hostname)

HARBOR_VOLUME=/tmp

mkdir -p $HARBOR_VOLUME



rm -f /tmp/ovs-subnets-unsorted
etcdctl ls /ovs/network/subnets | \
  while read ETCD_KEY; do
    OVS_DOCKER_SUBNET=$(echo ${ETCD_KEY#/ovs/network/subnets/} | tr '-' '/')
    echo "$OVS_DOCKER_SUBNET $(etcdctl get $ETCD_KEY)" >> /tmp/ovs-subnets-unsorted
  done
# Sort the the list of hosts and place it in the shared directory
sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 /tmp/ovs-subnets-unsorted > $HARBOR_VOLUME/ovs-subnets

${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ovs-vsctl list-ifaces docker0_ovs > /tmp/ovs_docker_tunnels
cat $HARBOR_VOLUME/ovs-subnets | \
  while read OVS_SUBNET; do
    REMOTE_IP=$(echo $OVS_SUBNET | awk '{print $2}' )
    REMOTE_SUBNET=$(echo $OVS_SUBNET | awk '{print $1}' )
    TUNNEL_NAME=$(echo $REMOTE_SUBNET | awk -F '.' '{print $1"_"$2"_"$3"_"$4}' | tr '/' '_')
    TUNNEL_NAME="${OVS_TUNNEL_TYPE}${TUNNEL_NAME}"
    if ping -c 1 ${REMOTE_IP} &> /dev/null; then
      echo "host ${REMOTE_IP} reachable"
      if [ "$REMOTE_IP" == "$OVS_IP" ]; then
        echo "Not going to add a tunnel as this is the local endpoint"
      else
        if grep -Fxq "$TUNNEL_NAME" /tmp/ovs_docker_tunnels; then
          echo "$TUNNEL_NAME already exists, and host is reachable"
        else
          ${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ovs-vsctl del-port docker0_ovs $TUNNEL_NAME || true
          ${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ovs-vsctl add-port docker0_ovs $TUNNEL_NAME -- set interface $TUNNEL_NAME type=${OVS_TUNNEL_TYPE} options:remote_ip=$REMOTE_IP
        fi
      fi
    else
      echo "host is not reachable, removing the bridge is it exists"
      ${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ovs-vsctl del-port docker0_ovs $TUNNEL_NAME || true
    fi
  done
