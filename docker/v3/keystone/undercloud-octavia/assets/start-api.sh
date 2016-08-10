#!/bin/sh
set -e
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
source /opt/config-octavia.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For DB"
################################################################################
wait-mysql


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Public Keystone"
################################################################################
wait-http $KEYSTONE_SERVICE_HOST:5000


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



octavia-db-manage --config-file $cfg upgrade head

exec octavia-api --config-file $cfg --debug
