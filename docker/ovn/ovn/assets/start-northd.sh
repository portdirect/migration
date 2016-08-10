#!/bin/bash
set -e
mkdir -p /var/run/openvswitch
exec ovn-northd --ovnnb-db=tcp:${OVS_NB_DB_IP}:6641 --ovnsb-db=tcp:${OVS_SB_DB_IP}:6642 --verbose
