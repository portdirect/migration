#!/bin/bash
OPENSTACK_COMPONENT="senlin"
COMPONENT_SUBCOMPONET="engine"

################################################################################
echo "${OS_DISTRO}: Global Configuration"
################################################################################
. /opt/harbor/harbor-common.sh
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Common Configuration"
################################################################################
. /opt/harbor/config-senlin.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Managing Database"
################################################################################
mysql -h ${MARIADB_SERVICE_HOST} -u root -p"${DB_ROOT_PASSWORD}" mysql << EOF
DROP DATABASE IF EXISTS ${SENLIN_DB_NAME};
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Managing Database"
################################################################################
mysql -h ${MARIADB_SERVICE_HOST} -u root -p"${DB_ROOT_PASSWORD}" mysql << EOF
CREATE DATABASE IF NOT EXISTS ${SENLIN_DB_NAME} DEFAULT CHARACTER SET utf8;
GRANT ALL PRIVILEGES ON ${SENLIN_DB_NAME}.* TO
    '${SENLIN_DB_USER}'@'%' IDENTIFIED BY '${SENLIN_DB_PASSWORD}'
EOF




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${COMPONENT_SUBCOMPONET}: Database"
################################################################################
/usr/bin/senlin-manage db_sync




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${COMPONENT_SUBCOMPONET}: Launching"
################################################################################
exec /usr/bin/senlin-engine --config-file /etc/senlin/senlin.conf