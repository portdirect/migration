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
: ${BARBICAN_DB_CA:="${MARIADB_CA}"}
: ${BARBICAN_DB_KEY:="${MARIADB_KEY}"}
: ${BARBICAN_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        BARBICAN_DB_USER BARBICAN_DB_PASSWORD BARBICAN_DB_NAME \
                        BARBICAN_DB_CA BARBICAN_DB_KEY BARBICAN_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg DEFAULT sql_connection "mysql://${BARBICAN_DB_USER}:${BARBICAN_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${BARBICAN_DB_NAME}?charset=utf8&ssl_ca=${BARBICAN_DB_CA}&ssl_key=${BARBICAN_DB_KEY}&ssl_cert=${BARBICAN_DB_CIRT}&ssl_verify_cert"
