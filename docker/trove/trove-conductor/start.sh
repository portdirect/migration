#!/bin/bash
set -o errexit
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
. /opt/harbor/config-trove.sh
: ${DEFAULT_REGION:="HarborOS"}


export cfg=/etc/trove/trove-conductor.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/trove/config-database.sh
. /opt/harbor/trove/config-rabbitmq.sh
crudini --set $cfg DEFAULT os_region_name "${DEFAULT_REGION}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /bin/sh -c "exec /usr/bin/trove-conductor --debug" trove
