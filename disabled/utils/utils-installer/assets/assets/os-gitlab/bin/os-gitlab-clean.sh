#!/bin/bash
set -e
OPENSTACK_COMPONENT=os-gitlab
OPENSTACK_SUBCOMPONENT=cleaner

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-common/common.env
source /etc/os-database/os-database.env
source /etc/os-database/credentials-os-database.env
source /etc/os-gitlab/os-gitlab.env
source /etc/os-gitlab/credentials-os-gitlab.env

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing Database"
################################################################################
mysql -h ${MARIADB_SERVICE_HOST} -u root -p${DB_ROOT_PASSWORD} mysql <<EOF
DROP DATABASE IF EXISTS ${gitlab_DB_NAME};
EOF
