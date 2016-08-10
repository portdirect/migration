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


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars MAGNUM_DB_PASSWORD MAGNUM_DB_NAME MAGNUM_DB_USER \
                    MARIADB_SERVICE_HOST DB_ROOT_PASSWORD
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db



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
CREATE DATABASE IF NOT EXISTS ${MAGNUM_DB_NAME} DEFAULT CHARACTER SET utf8 ;
GRANT ALL PRIVILEGES ON ${MAGNUM_DB_NAME}.* TO '${MAGNUM_DB_USER}'@'%' IDENTIFIED BY '${MAGNUM_DB_PASSWORD}' REQUIRE X509 ;
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${MAGNUM_DB_NAME}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Initializing the DB"
################################################################################
su -s /bin/sh -c "magnum-db-manage upgrade" magnum


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting the DB version"
################################################################################
su -s /bin/sh -c "magnum-db-manage version" magnum
