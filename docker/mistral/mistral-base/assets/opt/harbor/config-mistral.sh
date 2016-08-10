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



export cfg=/etc/mistral/mistral.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/mistral/config-keystone.sh
. /opt/harbor/mistral/config-database.sh
. /opt/harbor/mistral/config-rabbitmq.sh
. /opt/harbor/mistral/config-keystone-trust.sh
. /opt/harbor/mistral/config-cinder.sh
. /opt/harbor/mistral/config-ceilometer.sh
. /opt/harbor/mistral/config-barbican.sh
. /opt/harbor/mistral/config-bay.sh
