#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=database
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


: ${MARIADB_CA:="/etc/os-ssl-database/database-ca.crt"}
: ${MARIADB_KEY:="/etc/os-ssl-database/database.key"}
: ${MARIADB_CIRT:="/etc/os-ssl-database/database.crt"}
: ${CLOUDKITTY_DB_CA:="${MARIADB_CA}"}
: ${CLOUDKITTY_DB_KEY:="${MARIADB_KEY}"}
: ${CLOUDKITTY_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        CLOUDKITTY_DB_USER CLOUDKITTY_DB_PASSWORD CLOUDKITTY_DB_NAME \
                        CLOUDKITTY_DB_CA CLOUDKITTY_DB_KEY CLOUDKITTY_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg collect collector "ceilometer"
crudini --set $cfg collect services "compute,image,volume,network.floating"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Common: Keystone"
################################################################################
for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg ceilometer_collector $option
done
crudini --set $cfg ceilometer_collector auth_plugin "password"
crudini --set $cfg ceilometer_collector auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v3"
crudini --set $cfg ceilometer_collector auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg ceilometer_collector project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg ceilometer_collector user_domain_name "default"
crudini --set $cfg ceilometer_collector project_domain_name "default"
crudini --set $cfg ceilometer_collector username "${CLOUDKITTY_KEYSTONE_USER}"
crudini --set $cfg ceilometer_collector password "${CLOUDKITTY_KEYSTONE_PASSWORD}"
crudini --set $cfg ceilometer_collector auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg ceilometer_collector keystone_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg ceilometer_collector region "${DEFAULT_REGION}"
crudini --set $cfg ceilometer_collector cafile "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem"
crudini --set $cfg ceilometer_collector url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
