#!/bin/bash
set -e
OPENSTACK_COMPONENT=os-glusterfs

if [ ! -f /etc/os-container.env ]; then
  ################################################################################
  echo "${OS_DISTRO}: Generating local environment file from secrets_dir"
  ################################################################################
  SECRETS_DIR=/etc/os-config
  find $SECRETS_DIR -type f -printf "\n#%p\n" -exec bash -c "cat {} | sed  's|\\\n$||g'" \; > /etc/os-container.env
fi

################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env
: ${SKYDNS_BASE_KEY:="/harboros"}
: ${GLUSTERFS_DEVICE:="br0"}
: ${INITIAL_GLUSTER_HOSTS:="4"}
: ${GLUSTER_SKYDNS_PATH:="/storage/glusterfs"}
: ${GLUSTER_HOST:="$(hostname -s)"}
: ${OS_DOMAIN:="$(hostname -d)"}


################################################################################
echo "${OS_DISTRO}: Updating ETCD"
################################################################################
GLUSTER_IP=$(ip -f inet -o addr show ${GLUSTERFS_DEVICE}|cut -d\  -f 7 | cut -d/ -f 1)
GLUSTER_HOST=$(hostname -s)
etcdctl set ${SKYDNS_BASE_KEY}${GLUSTER_SKYDNS_PATH}/${GLUSTER_HOST} "${GLUSTER_IP}"
