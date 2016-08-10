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



export cfg=/etc/magnum/magnum.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/magnum/config-keystone.sh
. /opt/harbor/magnum/config-database.sh
. /opt/harbor/magnum/config-rabbitmq.sh
. /opt/harbor/magnum/config-keystone-trust.sh
. /opt/harbor/magnum/config-cinder.sh
. /opt/harbor/magnum/config-ceilometer.sh
. /opt/harbor/magnum/config-barbican.sh
. /opt/harbor/magnum/config-bay.sh
