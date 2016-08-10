#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=neutron
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/designate/common-vars.sh
: ${DEFAULT_REGION:="HarborOS"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: NEUTRON INTERACTION"
################################################################################
crudini --set $cfg network_api:neutron endpoints "${DEFAULT_REGION}|${KEYSTONE_AUTH_PROTOCOL}://${NEUTRON_API_SERVICE_HOST}"
crudini --set $cfg network_api:neutron timeout "30"
# crudini --set $cfg network_api:neutron admin_username "${DESIGNATE_KEYSTONE_USER}"
# crudini --set $cfg network_api:neutron admin_password "${DESIGNATE_KEYSTONE_PASSWORD}"
# crudini --set $cfg network_api:neutron admin_tenant_name "${SERVICE_TENANT_NAME}"
# crudini --set $cfg network_api:neutron auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_OLD_ADMIN_SERVICE_HOST}:35357/v2.0"
crudini --set $cfg network_api:neutron insecure "False"
crudini --set $cfg network_api:neutron auth_strategy "keystone"
crudini --set $cfg network_api:neutron ca_certificates_file "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
