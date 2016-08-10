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

PSQL_SERVICE_HOST=ipsilon-db.${OS_DOMAIN}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars IPSILON_USERS_DB_PASSWORD IPSILON_USERS_DB_NAME IPSILON_USERS_DB_USER \
                    PSQL_SERVICE_HOST IPSILON_DB_ROOT_PASSWORD
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
export PGPASSWORD=${IPSILON_DB_ROOT_PASSWORD}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Database"
################################################################################
psql -h ${PSQL_SERVICE_HOST} \
      --user root \
      --no-password <<EOF
CREATE USER ${IPSILON_USERS_DB_USER} WITH PASSWORD '${IPSILON_USERS_DB_PASSWORD}';
EOF
psql -h ${PSQL_SERVICE_HOST} \
      --user root \
      --no-password <<EOF
CREATE DATABASE ${IPSILON_USERS_DB_NAME};
EOF
psql -h ${PSQL_SERVICE_HOST} \
      --user root \
      --no-password <<EOF
GRANT ALL PRIVILEGES ON DATABASE ${IPSILON_USERS_DB_NAME} TO ${IPSILON_USERS_DB_USER} ;
EOF
