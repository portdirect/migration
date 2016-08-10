#!/bin/bash
set -e
ulimit -n 32000
/usr/share/openvswitch/scripts/ovs-ctl stop || true
/usr/share/openvswitch/scripts/ovs-ctl start --system-id=$(hostname -f)
tail -f /var/log/openvswitch/ovsdb-server.log /var/log/openvswitch/ovs-vswitchd.log
