#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=database
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/designate/common-vars.sh


: ${MARIADB_CA:="/etc/os-ssl-database/database-ca.crt"}
: ${MARIADB_KEY:="/etc/os-ssl-database/database.key"}
: ${MARIADB_CIRT:="/etc/os-ssl-database/database.crt"}
: ${DESIGNATE_DB_CA:="${MARIADB_CA}"}
: ${DESIGNATE_DB_KEY:="${MARIADB_KEY}"}
: ${DESIGNATE_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        DESIGNATE_DB_USER DESIGNATE_DB_PASSWORD DESIGNATE_DB_NAME \
                        DESIGNATE_DB_CA DESIGNATE_DB_KEY DESIGNATE_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg storage:sqlalchemy connection "mysql://${DESIGNATE_DB_USER}:${DESIGNATE_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DESIGNATE_DB_NAME}?charset=utf8&ssl_ca=${DESIGNATE_DB_CA}&ssl_key=${DESIGNATE_DB_KEY}&ssl_cert=${DESIGNATE_DB_CIRT}&ssl_verify_cert"
