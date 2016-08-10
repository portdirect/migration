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
: ${GNOCCHI_DB_CA:="${MARIADB_CA}"}
: ${GNOCCHI_DB_KEY:="${MARIADB_KEY}"}
: ${GNOCCHI_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        GNOCCHI_DB_USER GNOCCHI_DB_PASSWORD GNOCCHI_DB_NAME \
                        GNOCCHI_DB_CA GNOCCHI_DB_KEY GNOCCHI_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg database connection "mysql://${GNOCCHI_DB_USER}:${GNOCCHI_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${GNOCCHI_DB_NAME}?charset=utf8&ssl_ca=${GNOCCHI_DB_CA}&ssl_key=${GNOCCHI_DB_KEY}&ssl_cert=${GNOCCHI_DB_CIRT}&ssl_verify_cert"
crudini --set $cfg indexer url "mysql://${GNOCCHI_DB_USER}:${GNOCCHI_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${GNOCCHI_DB_NAME}?charset=utf8&ssl_ca=${GNOCCHI_DB_CA}&ssl_key=${GNOCCHI_DB_KEY}&ssl_cert=${GNOCCHI_DB_CIRT}&ssl_verify_cert"
