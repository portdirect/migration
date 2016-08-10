#!/bin/bash
set -e

OVN_DIR=/var/lib/ovn
OVN_LOG_DIR=/var/log/ovn
mkdir -p $OVN_DIR
mkdir -p $OVN_LOG_DIR

if [ ! -f  $OVN_DIR/ovnnb.db ]; then
    echo "Creating DB"
    ovsdb-tool create $OVN_DIR/ovnsb.db /usr/share/openvswitch/ovn-sb.ovsschema
fi


exec ovsdb-server  \
      --log-file=${OVN_LOG_DIR}/ovsdb-server-sb.log \
      --remote=punix:/var/run/openvswitch/ovnsb_db.sock \
      --remote=ptcp:6642:0.0.0.0 \
      --pidfile=/var/run/openvswitch/ovnsb_db.pid \
      --unixctl=ovnsb_db.ctl ${OVN_DIR}/ovnsb.db --verbose
