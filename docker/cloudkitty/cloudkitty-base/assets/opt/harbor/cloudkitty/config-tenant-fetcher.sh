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
                    SERVICE_TENANT_NAME CLOUDKITTY_FREEIPA_USER \
                    CLOUDKITTY_FREEIPA_PASSWORD KEYSTONE_API_VERSION


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Keystone"
################################################################################
crudini --set $cfg keystone_fetcher backend "keystone"
for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg keystone_fetcher $option
done
crudini --set $cfg keystone_fetcher auth_plugin "password"
crudini --set $cfg keystone_fetcher auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg keystone_fetcher url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
crudini --set $cfg keystone_fetcher auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg keystone_fetcher project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_fetcher user_domain_name "${OS_DOMAIN}"
crudini --set $cfg keystone_fetcher project_domain_name "default"
crudini --set $cfg keystone_fetcher username "${CLOUDKITTY_FREEIPA_USER}"
crudini --set $cfg keystone_fetcher password "${CLOUDKITTY_FREEIPA_PASSWORD}"
crudini --set $cfg keystone_fetcher auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg keystone_fetcher cafile "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
crudini --set $cfg keystone_fetcher keystone_version "${KEYSTONE_API_VERSION}"
