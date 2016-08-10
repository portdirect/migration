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
: ${NEUTRON_DB_CA:="${MARIADB_CA}"}
: ${NEUTRON_DB_KEY:="${MARIADB_KEY}"}
: ${NEUTRON_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        NEUTRON_DB_USER NEUTRON_DB_PASSWORD NEUTRON_DB_NAME \
                        NEUTRON_DB_CA NEUTRON_DB_KEY NEUTRON_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg database connection "mysql://${NEUTRON_DB_USER}:${NEUTRON_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${NEUTRON_DB_NAME}?charset=utf8&ssl_ca=${NEUTRON_DB_CA}&ssl_key=${NEUTRON_DB_KEY}&ssl_cert=${NEUTRON_DB_CIRT}&ssl_verify_cert"
