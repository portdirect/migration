#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=keystone
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${KEYSTONE_API_VERSION:="3"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_API_VERSION \
                    SERVICE_TENANT_NAME NOVA_KEYSTONE_USER \
                    NOVA_KEYSTONE_PASSWORD KEYSTONE_API_VERSION


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Keystone"
################################################################################
for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg nova $option
done
crudini --set $cfg nova auth_plugin "password"
crudini --set $cfg nova auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg nova auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg nova project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg nova user_domain_name "Default"
crudini --set $cfg nova project_domain_name "Default"
crudini --set $cfg nova username "${NOVA_KEYSTONE_USER}"
crudini --set $cfg nova password "${NOVA_KEYSTONE_PASSWORD}"
crudini --set $cfg nova auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg nova auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Producing OpenRC"
################################################################################
cat > /openrc-nova <<EOF
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
export OS_USERNAME="${NOVA_KEYSTONE_USER}"
export OS_PASSWORD="${NOVA_KEYSTONE_PASSWORD}"
export OS_PROJECT_DOMAIN_NAME="default"
export OS_USER_DOMAIN_NAME="default"
export OS_PROJECT_NAME="${SERVICE_TENANT_NAME}"
export OS_IDENTITY_API_VERSION="${KEYSTONE_API_VERSION}"
EOF
