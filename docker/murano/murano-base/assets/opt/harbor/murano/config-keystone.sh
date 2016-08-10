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
                    SERVICE_TENANT_NAME MURANO_KEYSTONE_USER \
                    MURANO_KEYSTONE_PASSWORD KEYSTONE_API_VERSION KEYSTONE_AUTH_PROTOCOL


################################################################################
echo "${OS_DISTRO}: CONFIG: Keystone"
################################################################################
for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_password; do
    crudini --del $cfg keystone_authtoken $option
done
#crudini --del $cfg keystone_authtoken cafile
crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg keystone_authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg keystone_authtoken auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}/v3"
crudini --set $cfg keystone_authtoken identity_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v3"
crudini --set $cfg keystone_authtoken admin_tenant_name  "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_authtoken admin_user "${MURANO_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken admin_password "${MURANO_KEYSTONE_PASSWORD}"
crudini --set $cfg keystone_authtoken auth_plugin "password"
crudini --set $cfg keystone_authtoken user_domain_name "Default"
crudini --set $cfg keystone_authtoken project_domain_name "Default"
crudini --set $cfg keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_authtoken username "${MURANO_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken password "${MURANO_KEYSTONE_PASSWORD}"
crudini --set $cfg keystone_authtoken cafile "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
crudini --set $cfg keystone_authtoken insecure "false"
crudini --set $cfg keystone_authtoken auth_host "${KEYSTONE_ADMIN_SERVICE_HOST}"
crudini --set $cfg keystone_authtoken auth_port "443"
crudini --set $cfg keystone_authtoken auth_protocol "${KEYSTONE_AUTH_PROTOCOL}"
crudini --set $cfg keystone_authtoken user_domain_name "Default"
crudini --set $cfg keystone_authtoken project_domain_name "Default"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating OpenRC"
################################################################################
cat > /openrc_${MURANO_KEYSTONE_USER} << EOF
export OS_USERNAME=${MURANO_KEYSTONE_USER}
export OS_PASSWORD=${MURANO_KEYSTONE_PASSWORD}
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=${DEFAULT_REGION}
export OS_PROJECT_NAME=${SERVICE_TENANT_NAME}
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_CACERT=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
export PS1="[(\${OS_USERNAME}@\${OS_USER_DOMAIN_NAME}:\${OS_PROJECT_NAME}) \\u@\\h \\W] ⌘ "
EOF
