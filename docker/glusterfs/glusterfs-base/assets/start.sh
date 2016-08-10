#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


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
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: updating dns so that $(hostname -s).storage.node.local points to ${GLUSTERFS_IP}"
################################################################################
etcdctl set /node-skydns/local/node/storage/$(hostname -s) "{\"host\":\"${GLUSTERFS_IP}\"}"
etcdctl set /master-skydns/local/node/storage/$(hostname -s) "{\"host\":\"${GLUSTERFS_IP}\"}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Prepping Volumes and mounts"
################################################################################
/opt/harbor/prep-discs.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Starting RPC BIND"
################################################################################
/sbin/rpcbind -w



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching Supervisord"
################################################################################
exec /usr/bin/supervisord -c /etc/supervisord.conf
