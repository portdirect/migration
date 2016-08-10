#!/bin/bash
set -e

################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        MARIADB_CA MARIADB_KEY MARIADB_CIRT \
                        NEUTRON_DB_USER NEUTRON_DB_PASSWORD NEUTRON_DB_NAME \
                        NEUTRON_DB_CA NEUTRON_DB_KEY NEUTRON_DB_CIRT
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db


################################################################################
echo "${OS_DISTRO}: Neutron: Updating Config"
################################################################################


core_cfg=/etc/neutron/neutron.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $core_cfg database connection "mysql://${NEUTRON_DB_USER}:${NEUTRON_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${NEUTRON_DB_NAME}?charset=utf8&ssl_ca=${NEUTRON_DB_CA}&ssl_key=${NEUTRON_DB_KEY}&ssl_cert=${NEUTRON_DB_CIRT}&ssl_verify_cert"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring DB exists with correct permissions"
################################################################################
mysql -h ${MARIADB_SERVICE_HOST} \
      -u root \
      -p"${DB_ROOT_PASSWORD}" \
      --ssl-key /etc/os-ssl-database/database.key \
      --ssl-cert /etc/os-ssl-database/database.crt \
      --ssl-ca /etc/os-ssl-database/database-ca.crt \
      --secure-auth \
      --ssl-verify-server-cert \
      mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${NEUTRON_DB_NAME} DEFAULT CHARACTER SET utf8 ;
GRANT ALL PRIVILEGES ON ${NEUTRON_DB_NAME}.* TO '${NEUTRON_DB_USER}'@'%' IDENTIFIED BY '${NEUTRON_DB_PASSWORD}' REQUIRE X509 ;
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${NEUTRON_DB_NAME}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Initializing the DB"
################################################################################
su -s /bin/bash -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
su -s /bin/bash -c "neutron-db-manage --service lbaas --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting the DB version"
################################################################################
su -s /bin/bash -c "neutron-db-manage current" neutron
