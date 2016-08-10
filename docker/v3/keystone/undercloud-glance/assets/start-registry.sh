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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Public Neutron"
################################################################################
wait-http $GLANCE_SERVICE_HOST:9292


cfg=/etc/${OS_COMP}/${OS_COMP}-registry.conf
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

exec glance-registry --config-file $cfg --debug
