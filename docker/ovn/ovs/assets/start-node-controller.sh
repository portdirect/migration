#!/bin/bash
set -e

TUNNEL_DEV=${TUNNEL_DEV:-eth0}
HOST_IP="$(ip -f inet -o addr show ${TUNNEL_DEV}|cut -d\  -f 7 | cut -d/ -f 1)"
OVS_SB_DB_IP=${OVS_SB_DB_IP:-$HOST_IP}
INTERGRATION_BRIDGE=${INTERGRATION_BRIDGE:-br-int}

ovs-vsctl --no-wait init
ovs-vsctl --no-wait set open_vswitch . system-type="HarborOS"
ovs-vsctl --no-wait set open_vswitch . external-ids:system-id="$(hostname -s).$(hostname -d)"

ovs-vsctl --no-wait set open_vswitch . external-ids:ovn-remote="tcp:${OVS_SB_DB_IP}:6642"
ovs-vsctl --no-wait set open_vswitch . external-ids:ovn-bridge="${INTERGRATION_BRIDGE}"
ovs-vsctl --no-wait set open_vswitch . external-ids:ovn-encap-type="geneve"
ovs-vsctl --no-wait set open_vswitch . external-ids:ovn-encap-ip="$HOST_IP"

ovs-vsctl --no-wait -- --may-exist add-br ${INTERGRATION_BRIDGE}
ovs-vsctl --no-wait br-set-external-id ${INTERGRATION_BRIDGE} bridge-id ${INTERGRATION_BRIDGE}
ovs-vsctl --no-wait set bridge br-int fail-mode=secure other-config:disable-in-band=true

exec ovn-controller --verbose unix:/var/run/openvswitch/db.sock
