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
: ${DEFAULT_REGION:="HarborOS"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Checking Env"
################################################################################


export cfg=/etc/trove/trove.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/trove/config-keystone.sh
. /opt/harbor/trove/config-database.sh
. /opt/harbor/trove/config-rabbitmq.sh
. /opt/harbor/trove/config-network.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SETTING GLOBAL TROVE PREFS"
################################################################################
crudini --set $cfg DEFAULT trove_auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
crudini --set $cfg DEFAULT os_region_name "${DEFAULT_REGION}"
crudini --set $cfg DEFAULT trove_volume_support "False"
crudini --set $cfg DEFAULT device_path "None"
crudini --set $cfg DEFAULT use_heat "True"
crudini --set $cfg DEFAULT heat_time_out "600"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SETTING UP DATABASE PREFS"
################################################################################
. /opt/harbor/trove/config-db-prefs.sh
