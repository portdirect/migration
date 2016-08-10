#!/bin/sh
set -e
MARIADB_SERVICE_HOST=${EXPOSED_IP}
KEYSTONE_SERVICE_HOST=${EXPOSED_IP}
RABBITMQ_SERVICE_HOST=${EXPOSED_IP}
GLANCE_REGISTRY_SERVICE_HOST=${EXPOSED_IP}
OVN_NORTHD_IP=${EXPOSED_IP}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}

DB_NAME=${OS_COMP}
DB_USER=${OS_COMP}
DB_PASSWORD=${DB_ROOT_PASSWORD}
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




cfg=/etc/${OS_COMP}/${OS_COMP}.conf
mkdir -p /etc/${OS_COMP}


crudini --set $cfg database connection "mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DB_NAME}?charset=utf8"


crudini --set $cfg keystone_authtoken auth_uri "http://${KEYSTONE_SERVICE_HOST}:35357"
crudini --set $cfg keystone_authtoken project_domain_name "default"
crudini --set $cfg keystone_authtoken project_name "service"
crudini --set $cfg keystone_authtoken user_domain_name "default"
crudini --set $cfg keystone_authtoken password "password"
crudini --set $cfg keystone_authtoken username "neutron"
crudini --set $cfg keystone_authtoken auth_url "http://${KEYSTONE_SERVICE_HOST}:35357/v3"
crudini --set $cfg keystone_authtoken auth_type "password"
crudini --set $cfg keystone_authtoken auth_version "v3"
crudini --set $cfg paste_deploy flavor "keystone"


crudini --set $cfg DEFAULT transport_url "rabbit://guest:guest@${RABBITMQ_SERVICE_HOST}:5672/"


crudini --set $cfg DEFAULT registry_host "${GLANCE_REGISTRY_SERVICE_HOST}"

crudini --set $cfg DEFAULT container_formats "docker"



crudini --set $cfg glance_store stores "file,http"
crudini --set $cfg glance_store default_store "file"
crudini --set $cfg glance_store filesystem_store_datadir "/var/lib/glance/images/"


glance-manage --config-file $cfg db sync
exec glance-api --config-file $cfg --debug --config-file /etc/${OS_COMP}/glance-api-paste.ini
