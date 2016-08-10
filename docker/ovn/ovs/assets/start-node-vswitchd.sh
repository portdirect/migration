#!/bin/bash
set -e

OVN_DIR=/var/lib/ovn
OVN_LOG_DIR=/var/log/ovn
mkdir -p $OVN_DIR
mkdir -p $OVN_LOG_DIR

exec ovs-vswitchd unix:/var/run/openvswitch/db.sock \
    --mlockall --no-chdir \
    --log-file=$OVN_LOG_DIR/ovs-vswitchd.log \
    --pidfile=/var/run/ovs-vswitchd.pid \
    --verbose
