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
echo "${OS_DISTRO}: Waiting for nodes"
################################################################################
REGISTERED_GLUSTER_HOSTS=$(etcdctl ls --recursive ${SKYDNS_BASE_KEY}/${GLUSTER_SKYDNS_PATH} | wc -l)
until [ "$REGISTERED_GLUSTER_HOSTS" -ge "$INITIAL_GLUSTER_HOSTS" ]; do
   echo "${REGISTERED_GLUSTER_HOSTS} of ${INITIAL_GLUSTER_HOSTS} inital hosts registered: waiting 2 seconds before polling again"
   sleep 2s
   REGISTERED_GLUSTER_HOSTS=$(etcdctl ls --recursive ${SKYDNS_BASE_KEY}/${GLUSTER_SKYDNS_PATH} | wc -l)
done
################################################################################
echo "${OS_DISTRO}: Waiting for nodes: Finished"
################################################################################


################################################################################
echo "${OS_DISTRO}: Checking UUID"
################################################################################
GLUSTERNODE_UUID=$(gluster pool list | grep "localhost" | awk '{print $1}')
etcdctl get "${SKYDNS_BASE_KEY}/gluster-uuids/$(hostname -s)" || etcdctl set ${SKYDNS_BASE_KEY}/gluster-uuids/$(hostname -s) $GLUSTERNODE_UUID
GLUSTERNODE_UUID_ETCD=$(etcdctl get "${SKYDNS_BASE_KEY}/gluster-uuids/$(hostname -s)")
if [ "$GLUSTERNODE_UUID" != "${GLUSTERNODE_UUID_ETCD}" ]; then
  echo "UUID does not match exiting"
  exit 1
fi


################################################################################
echo "${OS_DISTRO}:Building peer group"
################################################################################
while read -r REGISTERED_GLUSTER_HOST_KEY; do
  if [ "$REGISTERED_GLUSTER_HOST_KEY" != "${SKYDNS_BASE_KEY}/${GLUSTER_SKYDNS_PATH}/${GLUSTER_HOST}" ]; then
    REGISTERED_GLUSTER_HOST=$(etcdctl get $REGISTERED_GLUSTER_HOST_KEY )
    echo ".Attempting to peer probe $REGISTERED_GLUSTER_HOST"
    gluster peer probe ${REGISTERED_GLUSTER_HOST}
  fi
done <<< "$(etcdctl ls --recursive ${SKYDNS_BASE_KEY}/${GLUSTER_SKYDNS_PATH})"
gluster peer status
gluster pool list
