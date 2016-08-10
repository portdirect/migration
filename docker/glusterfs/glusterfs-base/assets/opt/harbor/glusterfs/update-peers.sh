#!/bin/bash
set -e
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars GLUSTERFS_DEVICE ETCDCTL_ENDPOINT


GLUSTERFS_IP=$(ip -f inet -o addr show $GLUSTERFS_DEVICE|cut -d\  -f 7 | cut -d/ -f 1)
HOSTNAME=$(hostname -s)

#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Registering Node IP"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes/${HOSTNAME}/ip || \
  etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes/${HOSTNAME}/ip ${GLUSTERFS_IP}
GLUSTERFS_IP_ETCD=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes/${HOSTNAME}/ip)
if [ "${GLUSTERFS_IP}" != "${GLUSTERFS_IP_ETCD}" ]; then
  #################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: IP registered in etcd does not match this node"
  ################################################################################
  etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes/${HOSTNAME}/ip ${GLUSTERFS_IP}
fi
etcdctl set /node-skydns/local/node/storage/$(hostname -s) "{\"host\":\"${GLUSTERFS_IP}\"}"


################################################################################
echo "${OS_DISTRO}: Checking UUID"
################################################################################
GLUSTERNODE_UUID="$(gluster pool list | grep "localhost" | awk '{print $1}')"
etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes/${HOSTNAME}/uuid || \
  etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes/${HOSTNAME}/uuid $GLUSTERNODE_UUID
GLUSTERNODE_UUID_ETCD=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes/${HOSTNAME}/uuid)
if [ "$GLUSTERNODE_UUID" != "${GLUSTERNODE_UUID_ETCD}" ]; then
  #################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: UUID registered in etcd does not match this node"
  ################################################################################
  echo "ETCD: ${GLUSTERNODE_UUID_ETCD}"
  echo "NODE: ${GLUSTERNODE_UUID}"
  exit 1
fi


################################################################################
echo "${OS_DISTRO}:Building/Updating peer group"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} ls --recursive /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes | while read -r REGISTERED_GLUSTER_HOST_ROOT; do
  echo "${OS_DISTRO}:REGISTERED_GLUSTER_HOST_ROOT:${REGISTERED_GLUSTER_HOST_ROOT}"
  PEER_IP_KEY="$(echo ${REGISTERED_GLUSTER_HOST_ROOT} | awk '/ip$/' )"
  echo "${OS_DISTRO}:PEER_IP_KEY:${PEER_IP_KEY}"
  if [ "$PEER_IP_KEY" != "" ]; then
    PEER_IP=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get ${PEER_IP_KEY})
    echo "${OS_DISTRO}:PEER_IP:${PEER_IP}"
    if [ "${PEER_IP}" != "${GLUSTERFS_IP}" ]; then
      PEER_IP=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get ${PEER_IP_KEY})
      PEER_HOSTNAME="$(echo ${PEER_IP_KEY} | awk -F '/' '{print $(NF-1)}' )"
      PEER_CLUSTER_FQDN="${PEER_HOSTNAME}.storage.node.local"
      if gluster peer status | grep -q ${PEER_CLUSTER_FQDN}; then
        #################################################################################
        echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Peer ${PEER_IP} is already probed"
        ################################################################################
      else
        #################################################################################
        echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Peer Probing ${PEER_IP}"
        ################################################################################
        gluster peer probe ${PEER_CLUSTER_FQDN}
      fi
    else
      #################################################################################
      echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Not Peer Probing ${PEER_IP}, as it belongs to this host"
      ################################################################################
    fi
  fi
done
