#!/bin/sh
set -e
MARIADB_SERVICE_HOST=${EXPOSED_IP}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}


DB_NAME=${OS_COMP}
DB_USER=${OS_COMP}
DB_PASSWORD=${DB_ROOT_PASSWORD}
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For DB"
################################################################################
wait-mysql

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Admin Keystone"
################################################################################
wait-http $KEYSTONE_SERVICE_HOST:35357

mkdir -p /etc/keystone
cfg=/etc/keystone/keystone.conf
crudini --set $cfg database connection "mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DB_NAME}?charset=utf8"

exec keystone-wsgi-public --port 5000  -- --config-file=$cfg --debug
