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
                    SERVICE_TENANT_NAME GLANCE_KEYSTONE_USER \
                    GLANCE_KEYSTONE_PASSWORD KEYSTONE_API_VERSION


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Keystone"
################################################################################
for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg keystone_authtoken $option
done


crudini --set $cfg paste_deploy flavor keystone
crudini --set $cfg keystone_authtoken auth_plugin "password"
crudini --set $cfg keystone_authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg keystone_authtoken auth_version "v3"
crudini --set $cfg keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_authtoken user_domain_name "Default"
crudini --set $cfg keystone_authtoken project_domain_name "Default"
crudini --set $cfg keystone_authtoken username "${GLANCE_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken password "${GLANCE_KEYSTONE_PASSWORD}"
crudini --set $cfg keystone_authtoken auth_version "v3"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating OpenRC"
################################################################################
cat > /openrc_${GLANCE_KEYSTONE_USER} << EOF
export OS_USERNAME=${GLANCE_KEYSTONE_USER}
export OS_PASSWORD=${GLANCE_KEYSTONE_PASSWORD}
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=${DEFAULT_REGION}
export OS_PROJECT_NAME=${SERVICE_TENANT_NAME}
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export PS1="[(\${OS_USERNAME}@\${OS_USER_DOMAIN_NAME}:\${OS_PROJECT_NAME}) \\u@\\h \\W] ⌘ "
EOF
