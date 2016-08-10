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
: ${TROVE_DB_CA:="${MARIADB_CA}"}
: ${TROVE_DB_KEY:="${MARIADB_KEY}"}
: ${TROVE_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        TROVE_DB_USER TROVE_DB_PASSWORD TROVE_DB_NAME \
                        TROVE_DB_CA TROVE_DB_KEY TROVE_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg database connection "mysql://${TROVE_DB_USER}:${TROVE_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${TROVE_DB_NAME}?charset=utf8&ssl_ca=${TROVE_DB_CA}&ssl_key=${TROVE_DB_KEY}&ssl_cert=${TROVE_DB_CIRT}&ssl_verify_cert"
