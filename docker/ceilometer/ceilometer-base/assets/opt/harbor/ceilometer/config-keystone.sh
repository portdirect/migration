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
: ${CEILOMETER_API_VERSION:="2"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_API_VERSION \
                    SERVICE_TENANT_NAME CEILOMETER_KEYSTONE_USER \
                    CEILOMETER_KEYSTONE_PASSWORD KEYSTONE_API_VERSION


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Keystone"
################################################################################
crudini --set $cfg DEFAULT auth_strategy "keystone"
for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg keystone_authtoken $option
done
crudini --set $cfg keystone_authtoken auth_plugin "password"
crudini --set $cfg keystone_authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_authtoken user_domain_name "Default"
crudini --set $cfg keystone_authtoken project_domain_name "Default"
crudini --set $cfg keystone_authtoken username "${CEILOMETER_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken password "${CEILOMETER_KEYSTONE_PASSWORD}"
crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Producing OpenRC"
################################################################################
cat > /openrc <<EOF
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
export OS_USERNAME="${CEILOMETER_KEYSTONE_USER}"
export OS_PASSWORD="${CEILOMETER_KEYSTONE_PASSWORD}"
export OS_PROJECT_DOMAIN_NAME="default"
export OS_USER_DOMAIN_NAME="default"
export OS_PROJECT_NAME="${SERVICE_TENANT_NAME}"
export OS_VOLUME_API_VERSION=$CEILOMETER_API_VERSION
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Keystone: SERVICE_CREDENTIALS"
################################################################################
#[service_credentials]

#
# Options defined in ceilometer.service
#

# User name to use for OpenStack service access. (string
# value)
crudini --set $cfg service_credentials os_username "${CEILOMETER_KEYSTONE_USER}"

# Password to use for OpenStack service access. (string value)
crudini --set $cfg service_credentials os_password "${CEILOMETER_KEYSTONE_PASSWORD}"

# Tenant ID to use for OpenStack service access. (string
# value)
#os_tenant_id=

# Tenant name to use for OpenStack service access. (string
# value)
crudini --set $cfg service_credentials os_tenant_name "${SERVICE_TENANT_NAME}"

# Certificate chain for SSL validation. (string value)
#os_cacert=<None>

# Auth URL to use for OpenStack service access. (string value)
crudini --set $cfg service_credentials os_auth_url "${KEYSTONE_AUTH_PROTOCOL}://keystone-v2.${OS_DOMAIN}:35357/v2.0"

# Region name to use for OpenStack service endpoints. (string
# value)
crudini --set $cfg service_credentials os_region_name "${DEFAULT_REGION}"

# Type of endpoint in Identity service catalog to use for
# communication with OpenStack services. (string value)35357
#os_endpoint_type=publicURL

# Disables X.509 certificate validation when an SSL connection
# to Identity Service is established. (boolean value)
#insecure=false
