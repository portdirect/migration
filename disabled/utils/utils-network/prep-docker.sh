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

OVS_CIDR=${OVS_NETWORK#*/}
OVS_NETWORK_START=${OVS_NETWORK%/*}
OVS_IP=$(ip -f inet -o addr show $OVS_DEV|cut -d\  -f 7 | cut -d/ -f 1)
HOSTNAME=$(hostname)
OVS_HOST_SUBNET=$(etcdctl get /ovs/network/nodes/$HOSTNAME)
DOCKER_BRIDGE_IP=$(sipcalc ${OVS_HOST_SUBNET} | grep "Usable range" | awk '{print $4}')
DOCKER_BRIDGE_ADDRESS="${DOCKER_BRIDGE_IP}/${OVS_NETWORK_CIDR}"


(
# Deactivate the docker0 bridge
(${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ip link set ${DOCKER_BRIDGE_NAME} down) || true
# Deactivate the Open vSwitch bridge
(${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ip link set ${OVS_BRIDGE_NAME} down) || true
# Remove the docker0 bridge
(${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} brctl delbr ${DOCKER_BRIDGE_NAME}) || true
# Delete the Open vSwitch bridge
(${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ovs-vsctl del-br ${OVS_BRIDGE_NAME}) || true
# Add the docker0 bridge
${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} brctl addbr ${DOCKER_BRIDGE_NAME}
# Set up the IP for the docker0 bridge
${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ip addr add ${DOCKER_BRIDGE_ADDRESS} dev ${DOCKER_BRIDGE_NAME}
# Activate the bridge
${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ip link set ${DOCKER_BRIDGE_NAME} up
# Add the br0 Open vSwitch bridge
${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ovs-vsctl add-br ${OVS_BRIDGE_NAME}
# Add the br0 bridge to docker0 bridge
${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} brctl addif ${DOCKER_BRIDGE_NAME} ${OVS_BRIDGE_NAME}
# Activate the bridge
${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ip link set ${OVS_BRIDGE_NAME} up
# Enable STP for meshed networking
${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ovs-vsctl set bridge ${OVS_BRIDGE_NAME} stp_enable=true
# List the ovs setup
${DOCKER_COMMAND} exec ${OVS_CONTAINER_NAME} ovs-vsctl show

)
