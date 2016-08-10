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
: ${BARBICAN_API_VERSION:="2"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg_api_paste KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_API_VERSION \
                    SERVICE_TENANT_NAME BARBICAN_KEYSTONE_USER \
                    BARBICAN_KEYSTONE_PASSWORD KEYSTONE_API_VERSION


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Keystone"
################################################################################
for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg_api_paste filter:keystone_authtoken $option
done
crudini --set $cfg_api_paste filter:keystone_authtoken auth_plugin "password"
crudini --set $cfg_api_paste filter:keystone_authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg_api_paste filter:keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg_api_paste filter:keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg_api_paste filter:keystone_authtoken user_domain_name "Default"
crudini --set $cfg_api_paste filter:keystone_authtoken project_domain_name "Default"
crudini --set $cfg_api_paste filter:keystone_authtoken username "${BARBICAN_KEYSTONE_USER}"
crudini --set $cfg_api_paste filter:keystone_authtoken password "${BARBICAN_KEYSTONE_PASSWORD}"
crudini --set $cfg_api_paste filter:keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"



# crudini --set $cfg filter:keystone_authtoken auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}/v3"
# crudini --set $cfg filter:keystone_authtoken identity_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v3"
# crudini --set $cfg filter:keystone_authtoken admin_tenant_name  "${SERVICE_TENANT_NAME}"
# crudini --set $cfg filter:keystone_authtoken admin_user "${BARBICAN_KEYSTONE_USER}"
# crudini --set $cfg filter:keystone_authtoken admin_password "${BARBICAN_KEYSTONE_PASSWORD}"






################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Producing OpenRC"
################################################################################
cat > /openrc <<EOF
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
export OS_USERNAME="${BARBICAN_KEYSTONE_USER}"
export OS_PASSWORD="${BARBICAN_KEYSTONE_PASSWORD}"
export OS_PROJECT_DOMAIN_NAME="default"
export OS_USER_DOMAIN_NAME="default"
export OS_PROJECT_NAME="${SERVICE_TENANT_NAME}"
export OS_VOLUME_API_VERSION=$BARBICAN_API_VERSION
EOF
