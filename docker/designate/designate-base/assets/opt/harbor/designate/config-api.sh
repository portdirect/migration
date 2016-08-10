#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=api
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/designate/common-vars.sh
: ${DEFAULT_REGION:="HarborOS"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: API"
################################################################################
crudini --set $cfg service:api api_base_uri "${KEYSTONE_AUTH_PROTOCOL}://${DESIGNATE_API_SERVICE_HOST}/"

crudini --set $cfg service:api enable_api_v1 "True"
crudini --set $cfg service:api enable_api_v2 "True"
crudini --set $cfg service:api enable_api_admin "True"

crudini --set $cfg service:api enabled_extensions_v1 "quotas"
crudini --set $cfg service:api enabled_extensions_v2 ""
crudini --set $cfg service:api enabled_extensions_admin "quotas"
