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
: ${MANILA_DB_CA:="${MARIADB_CA}"}
: ${MANILA_DB_KEY:="${MARIADB_KEY}"}
: ${MANILA_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        MANILA_DB_USER MANILA_DB_PASSWORD MANILA_DB_NAME \
                        MANILA_DB_CA MANILA_DB_KEY MANILA_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg database connection "mysql://${MANILA_DB_USER}:${MANILA_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${MANILA_DB_NAME}?charset=utf8&ssl_ca=${MANILA_DB_CA}&ssl_key=${MANILA_DB_KEY}&ssl_cert=${MANILA_DB_CIRT}&ssl_verify_cert"
