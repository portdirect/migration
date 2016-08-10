#!/bin/bash
OPENSTACK_COMPONENT="sahara"

: ${SAHARA_DB_USER:=sahara}
: ${SAHARA_DB_NAME:=sahara}
: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${CINDER_KEYSTONE_USER:=sahara}
: ${ADMIN_USER:="admin"}
: ${ADMIN_USER_DOMAIN:="default"}
: ${ADMIN_USER_PROJECT_DOMAIN:="default"}
: ${DEFAULT_REGION:="HarborOS"}





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Managing Database"
################################################################################
mysql -h ${MARIADB_SERVICE_HOST} -u root -p"${DB_ROOT_PASSWORD}" mysql << EOF
CREATE DATABASE IF NOT EXISTS ${SAHARA_DB_NAME};
GRANT ALL PRIVILEGES ON ${SAHARA_DB_NAME}.* TO
    '${SAHARA_DB_USER}'@'%' IDENTIFIED BY '${SAHARA_DB_PASSWORD}'
EOF



cfg="/etc/sahara/sahara.conf"
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: Database"
################################################################################
crudini --set $cfg database connection "mysql://${SAHARA_DB_USER}:${SAHARA_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${SAHARA_DB_NAME}"






################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config: RabbitMQ"
################################################################################
crudini --set $cfg DEFAULT rpc_backend rabbit
crudini --set $cfg oslo_messaging_rabbit rabbit_host ${RABBITMQ_SERVICE_HOST}
crudini --set $cfg oslo_messaging_rabbit rabbit_port "5672"
crudini --set $cfg oslo_messaging_rabbit rabbit_hosts ${RABBITMQ_SERVICE_HOST}:5672
crudini --set $cfg oslo_messaging_rabbit rabbit_use_ssl "False"
crudini --set $cfg oslo_messaging_rabbit rabbit_userid ${RABBITMQ_USERID}
crudini --set $cfg oslo_messaging_rabbit rabbit_password "${RABBITMQ_PASS}"
crudini --set $cfg oslo_messaging_rabbit rabbit_virtual_host "/"
crudini --set $cfg oslo_messaging_rabbit rabbit_ha_queues "False"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Keystone"
################################################################################
crudini --set $cfg DEFAULT auth_strategy "keystone"
crudini --set $cfg keystone_authtoken auth_plugin "password"
crudini --set $cfg keystone_authtoken auth_url "http://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"
crudini --set $cfg keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_authtoken user_domain_name "Default"
crudini --set $cfg keystone_authtoken project_domain_name "Default"
crudini --set $cfg keystone_authtoken username "${SAHARA_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken password "${SAHARA_KEYSTONE_PASSWORD}"
crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"





#crudini --set $cfg DEFAULT enable_notifications "true"
#crudini --set $cfg DEFAULT notification_driver "messaging"



crudini --set $cfg DEFAULT use_floating_ips "False"


crudini --set $cfg DEFAULT node_domain "novalocal"
crudini --set $cfg DEFAULT use_neutron "True"
crudini --set $cfg DEFAULT use_namespaces "True"
