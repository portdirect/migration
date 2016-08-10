#!/bin/bash
set -e

OVN_DIR=/var/lib/ovn
OVN_LOG_DIR=/var/log/ovn
mkdir -p $OVN_DIR
mkdir -p $OVN_LOG_DIR

if [ ! -f  $OVN_DIR/ovnnb.db ]; then
    echo "Creating DB"
    ovsdb-tool create $OVN_DIR/ovnnb.db /usr/share/openvswitch/ovn-nb.ovsschema
fi


exec ovsdb-server \
      --log-file=${OVN_LOG_DIR}/ovsdb-server-nb.log \
      --remote=punix:/var/run/openvswitch/ovnnb_db.sock \
      --remote=ptcp:6641:0.0.0.0 \
      --pidfile=/var/run/openvswitch/ovnnb_db.pid \
      --unixctl=ovnnb_db.ctl ${OVN_DIR}/ovnnb.db --verbose
