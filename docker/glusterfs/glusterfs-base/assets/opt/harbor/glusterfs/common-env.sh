#!/bin/sh

: ${HARBOR_GLUSTER_VG:=harbor-gluster}


: ${HARBOR_GLUSTER_DATA_POOL:=gluster-pool}
: ${HARBOR_GLUSTER_DATA_POOL_SIZE:='90%FREE'}
: ${HARBOR_GLUSTER_DATA_METADATA_SIZE:=1G}

HOSTNAME="$(hostname -s)"
HARBOROS_ETCD_ROOT="/harboros"
GLUSTER_ROLE="glusterfs"
