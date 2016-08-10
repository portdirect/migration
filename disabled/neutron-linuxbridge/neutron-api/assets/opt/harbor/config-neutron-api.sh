#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${MARIADB_CA:="/etc/os-ssl-database/database-ca.crt"}
: ${MARIADB_KEY:="/etc/os-ssl-database/database.key"}
: ${MARIADB_CIRT:="/etc/os-ssl-database/database.crt"}
: ${NEUTRON_DB_CA:="${MARIADB_CA}"}
: ${NEUTRON_DB_KEY:="${MARIADB_KEY}"}
: ${NEUTRON_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_SERVICE_HOST \
                    KEYSTONE_AUTH_PROTOCOL NOVA_API_SERVICE_HOST \
                    NOVA_KEYSTONE_USER NOVA_KEYSTONE_PASSWORD \
                    NEUTRON_DB_NAME NEUTRON_DB_USER NEUTRON_DB_PASSWORD \
                    NEUTRON_DB_CA NEUTRON_DB_KEY NEUTRON_DB_CIRT \
                    NEUTRON_API_SERVICE_HOST \
                    NEUTRON_FLAT_NETWORK_NAME NEUTRON_FLAT_NETWORK_INTERFACE


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
export cfg=/etc/neutron/neutron.conf
ml2_cfg=/etc/neutron/plugins/ml2/ml2_conf.ini


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/neutron/config-database.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Nova"
################################################################################
crudini --set $cfg DEFAULT notify_nova_on_port_status_changes "True"
crudini --set $cfg DEFAULT notify_nova_on_port_data_changes "True"
crudini --set $cfg DEFAULT nova_url "${KEYSTONE_AUTH_PROTOCOL}://${NOVA_API_SERVICE_HOST}/v2"
crudini --set $cfg nova auth_plugin "password"
crudini --set $cfg nova auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v3"
crudini --set $cfg nova username "${NOVA_KEYSTONE_USER}"
crudini --set $cfg nova password "${NOVA_KEYSTONE_PASSWORD}"
crudini --set $cfg nova user_domain_id "default"
crudini --set $cfg nova project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg nova project_domain_id "default"
crudini --set $cfg nova region_name "${DEFAULT_REGION}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Linux Bridge"
################################################################################
if [[ ${MECHANISM_DRIVERS} =~ linuxbridge ]]; then
  crudini --set $ml2_cfg   linux_bridge   bridge_mappings   "${NEUTRON_FLAT_NETWORK_NAME}:${NEUTRON_FLAT_NETWORK_INTERFACE}"
fi
