#!/bin/bash
set -e
OPENSTACK_COMPONENT=os-horizon
OPENSTACK_SUBCOMPONENT=cleaner

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-common/common.env
source /etc/os-database/os-database.env
source /etc/os-database/credentials-os-database.env
source /etc/os-horizon/os-horizon.env
source /etc/os-horizon/credentials-os-horizon.env

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing Database"
################################################################################
mysql -h ${MARIADB_SERVICE_HOST} -u root -p${DB_ROOT_PASSWORD} mysql <<EOF
DROP DATABASE IF EXISTS ${HORIZON_DB_NAME};
EOF
