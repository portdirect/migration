#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=peer-monitor
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


sleep 5s
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting for Glusterd to start"
################################################################################
until gluster peer status; do
  echo "Gluster is not running"
  sleep 10s
done

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Running Initial Update"
################################################################################
/opt/harbor/glusterfs/update-peers.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Watching ETCD @ /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes and running the peer update script on any change"
################################################################################
while true; do
   etcdctl --endpoint ${ETCDCTL_ENDPOINT} exec-watch --recursive /${OS_DISTRO}/${OPENSTACK_COMPONENT}/nodes -- /opt/harbor/glusterfs/update-peers.sh
done
