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


export cfg=/etc/cloudkitty/cloudkitty.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/cloudkitty/config-rabbitmq.sh
. /opt/harbor/cloudkitty/config-keystone.sh
. /opt/harbor/cloudkitty/config-database.sh
. /opt/harbor/cloudkitty/config-collector.sh
. /opt/harbor/cloudkitty/config-tenant-fetcher.sh
