#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=common-config
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Checking Env"
################################################################################



export cfg=/etc/gnocchi/gnocchi.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/gnocchi/config-glusterfs.sh
. /opt/harbor/gnocchi/config-keystone.sh
. /opt/harbor/gnocchi/config-database.sh

crudini --set $cfg storage coordination_url "etcd://etcd.os-etcd.svc.${OS_DOMAIN}:4001/${OPENSTACK_COMPONENT}"
