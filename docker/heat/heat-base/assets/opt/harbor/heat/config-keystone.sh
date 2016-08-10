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
: ${SERVICE_TENANT_NAME:="services"}
: ${DEFAULT_REGION:="HarborOS"}
: ${HEAT_DOMAIN:="heat"}
: ${HEAT_API_CFN_SERVICE_PORT:="8000"}




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_API_VERSION \
                    SERVICE_TENANT_NAME HEAT_KEYSTONE_USER \
                    HEAT_KEYSTONE_PASSWORD KEYSTONE_API_VERSION ETCDCTL_ENDPOINT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Heat Domain ID"
################################################################################
: ${HEAT_DOMAIN_ID:="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/heat-domain-id)"}
check_required_vars HEAT_DOMAIN_ID


################################################################################
echo "${OS_DISTRO}: CONFIG: Keystone"
################################################################################
crudini --set $cfg keystone_authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_authtoken username "${HEAT_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken password "${HEAT_KEYSTONE_PASSWORD}"
crudini --set $cfg keystone_authtoken user_domain_name "Default"
crudini --set $cfg keystone_authtoken project_domain_name "Default"
crudini --set $cfg keystone_authtoken admin_password "${HEAT_KEYSTONE_PASSWORD}"
crudini --set $cfg keystone_authtoken admin_tenant_name "${SERVICE_TENANT_NAME}"
#crudini --set $cfg keystone_authtoken admin_token ""
crudini --set $cfg keystone_authtoken admin_user "${HEAT_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken auth_admin_prefix ""
crudini --set $cfg keystone_authtoken auth_host "${KEYSTONE_ADMIN_SERVICE_HOST}/"
crudini --set $cfg keystone_authtoken auth_plugin "password"
crudini --set $cfg keystone_authtoken auth_port "443"
crudini --set $cfg keystone_authtoken auth_protocol "${KEYSTONE_AUTH_PROTOCOL}"
#crudini --set $cfg keystone_authtoken auth_section ""
crudini --set $cfg keystone_authtoken auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}/v3"
crudini --set $cfg keystone_authtoken auth_version "v3"
# crudini --set $cfg keystone_authtoken cache ""
# crudini --set $cfg keystone_authtoken cafile ""
# crudini --set $cfg keystone_authtoken certfile ""
# crudini --set $cfg keystone_authtoken check_revocations_for_cached ""
# crudini --set $cfg keystone_authtoken delay_auth_decision ""
# crudini --set $cfg keystone_authtoken enforce_token_bind ""
# crudini --set $cfg keystone_authtoken hash_algorithms ""
# crudini --set $cfg keystone_authtoken http_connect_timeout ""
# crudini --set $cfg keystone_authtoken http_request_max_retries ""
crudini --set $cfg keystone_authtoken identity_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v3"
# crudini --set $cfg keystone_authtoken include_service_catalog ""
crudini --set $cfg keystone_authtoken insecure "True"
# crudini --set $cfg keystone_authtoken keyfile ""
# crudini --set $cfg keystone_authtoken memcache_pool_conn_get_timeout ""
# crudini --set $cfg keystone_authtoken memcache_pool_dead_retry ""
# crudini --set $cfg keystone_authtoken memcache_pool_maxsize ""
# crudini --set $cfg keystone_authtoken memcache_pool_socket_timeout ""
# crudini --set $cfg keystone_authtoken memcache_pool_unused_timeout ""
# crudini --set $cfg keystone_authtoken memcache_secret_key ""
# crudini --set $cfg keystone_authtoken memcache_security_strategy ""
# crudini --set $cfg keystone_authtoken memcache_use_advanced_pool ""
# crudini --set $cfg keystone_authtoken memcached_servers ""
# crudini --set $cfg keystone_authtoken region_name ""
# crudini --set $cfg keystone_authtoken revocation_cache_time ""
# crudini --set $cfg keystone_authtoken signing_dir ""
# crudini --set $cfg keystone_authtoken token_cache_time ""



################################################################################
echo "${OS_DISTRO}: CONFIG: Trustee"
################################################################################
crudini --set $cfg trustee auth_plugin "password"
crudini --set $cfg trustee auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg trustee username "${HEAT_KEYSTONE_USER}"
crudini --set $cfg trustee password "${HEAT_KEYSTONE_PASSWORD}"
crudini --del $cfg trustee user_domain_id
crudini --set $cfg trustee user_domain_name "Default"



################################################################################
echo "${OS_DISTRO}: CONFIG: Stack Domain Admin"
################################################################################
crudini --set $cfg DEFAULT stack_domain_admin "${HEAT_KEYSTONE_USER}_admin"
crudini --set $cfg DEFAULT stack_domain_admin_password "${HEAT_KEYSTONE_PASSWORD}"
crudini --set $cfg DEFAULT stack_user_domain_id "${HEAT_DOMAIN_ID}"



################################################################################
echo "${OS_DISTRO}: CONFIG: EC2 Authtoken "
################################################################################
crudini --set $cfg ec2authtoken auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}:443/v3"





################################################################################
echo "${OS_DISTRO}: Generating openrc for ${HEAT_KEYSTONE_USER}"
################################################################################
cat > /openrc_${HEAT_KEYSTONE_USER} << EOF
export OS_USERNAME=${HEAT_KEYSTONE_USER}
export OS_PASSWORD=${HEAT_KEYSTONE_PASSWORD}
export OS_AUTH_URL=${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}/v3
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=${DEFAULT_REGION}
export OS_PROJECT_NAME=${SERVICE_TENANT_NAME}
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export PS1="[(${OS_USERNAME}@${OS_USER_DOMAIN_NAME}:${OS_PROJECT_NAME}) \\u@\\h \\W] ⌘ "
EOF

################################################################################
echo "${OS_DISTRO}: Generating openrc for ${HEAT_KEYSTONE_USER}_admin"
################################################################################
cat > /openrc_${HEAT_KEYSTONE_USER}_admin << EOF
export OS_USERNAME=${HEAT_KEYSTONE_USER}_admin
export OS_PASSWORD=${HEAT_KEYSTONE_PASSWORD}
export OS_AUTH_URL=${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}/v3
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=${DEFAULT_REGION}
export OS_PROJECT_DOMAIN_NAME=${HEAT_DOMAIN}
export OS_USER_DOMAIN_NAME=${HEAT_DOMAIN}
export PS1="[(${OS_USERNAME}@${OS_USER_DOMAIN_NAME}:${OS_PROJECT_NAME}) \\u@\\h \\W] ⌘ "
EOF
