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
: ${MURANO_DB_CA:="${MARIADB_CA}"}
: ${MURANO_DB_KEY:="${MARIADB_KEY}"}
: ${MURANO_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        MURANO_DB_USER MURANO_DB_PASSWORD MURANO_DB_NAME \
                        MURANO_DB_CA MURANO_DB_KEY MURANO_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg database connection "mysql://${MURANO_DB_USER}:${MURANO_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${MURANO_DB_NAME}?charset=utf8&ssl_ca=${MURANO_DB_CA}&ssl_key=${MURANO_DB_KEY}&ssl_cert=${MURANO_DB_CIRT}&ssl_verify_cert"
