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
check_required_vars TROVE_DB_PASSWORD TROVE_DB_NAME TROVE_DB_USER \
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
CREATE DATABASE IF NOT EXISTS ${TROVE_DB_NAME} DEFAULT CHARACTER SET utf8 ;
GRANT ALL PRIVILEGES ON ${TROVE_DB_NAME}.* TO '${TROVE_DB_USER}'@'%' IDENTIFIED BY '${TROVE_DB_PASSWORD}' REQUIRE X509 ;
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${TROVE_DB_NAME}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Initializing the DB"
################################################################################
su -s /bin/sh -c "trove-manage --debug db_sync" trove || (
  # https://bugzilla.redhat.com/show_bug.cgi?id=1196731 <- should only affect initial sync
  mysql -h ${MARIADB_SERVICE_HOST} \
        -u root \
        -p"${DB_ROOT_PASSWORD}" \
        --ssl-key /etc/os-ssl-database/database.key \
        --ssl-cert /etc/os-ssl-database/database.crt \
        --ssl-ca /etc/os-ssl-database/database-ca.crt \
        --secure-auth \
        --ssl-verify-server-cert \
        mysql <<EOF
use ${TROVE_DB_NAME} ;
SET GLOBAL foreign_key_checks=0;
EOF

  su -s /bin/sh -c "trove-manage --debug db_sync" trove

  mysql -h ${MARIADB_SERVICE_HOST} \
        -u root \
        -p"${DB_ROOT_PASSWORD}" \
        --ssl-key /etc/os-ssl-database/database.key \
        --ssl-cert /etc/os-ssl-database/database.crt \
        --ssl-ca /etc/os-ssl-database/database-ca.crt \
        --secure-auth \
        --ssl-verify-server-cert \
        mysql <<EOF
use ${TROVE_DB_NAME} ;
SET GLOBAL foreign_key_checks=1;
EOF
  )
