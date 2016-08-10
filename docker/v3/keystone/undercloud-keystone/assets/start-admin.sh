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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring DB exists with correct permissions"
################################################################################
# mysql -h ${MARIADB_SERVICE_HOST} \
#       -u root \
#       -p"${DB_ROOT_PASSWORD}" \
#       mysql <<EOF
# DROP DATABASE IF EXISTS ${DB_NAME};
# EOF
mysql -h ${MARIADB_SERVICE_HOST} \
      -u root \
      -p"${DB_ROOT_PASSWORD}" \
      mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8 ;
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}' ;
EOF

mkdir -p /etc/keystone
cfg=/etc/keystone/keystone.conf
crudini --set $cfg database connection "mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DB_NAME}?charset=utf8"

keystone-manage --config-file=$cfg --debug db_sync
keystone-manage --config-file=$cfg --debug bootstrap \
--bootstrap-username admin \
--bootstrap-password ${KEYSTONE_ADMIN_PASSWORD} \
--bootstrap-project-name admin \
--bootstrap-admin-url http://${EXPOSED_IP}:35357/v3 \
--bootstrap-public-url http://${EXPOSED_IP}:5000/v3 \
--bootstrap-internal-url http://${EXPOSED_IP}:5000/v3 \
--bootstrap-region-id RegionOne

exec keystone-wsgi-admin --port 35357  -- --config-file=/etc/keystone/keystone.conf --debug
