#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=common-config
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${MURANO_DNS:="8.8.8.8"}
: ${EXTERNAL_NET_NAME:="External"}
: ${MURANO_ROUTER_NAME:="Murano"}
: ${MURANO_API_SERVICE_PORT:="8082"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars MURANO_DB_PASSWORD MURANO_KEYSTONE_PASSWORD \
                    KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_PUBLIC_SERVICE_PORT \
                    MURANO_KEYSTONE_USER \
                    MURANO_DB_USER MURANO_DB_NAME KEYSTONE_AUTH_PROTOCOL \
                    KEYSTONE_PUBLIC_SERVICE_PORT RABBITMQ_SERVICE_HOST \
                    DEBUG

fail_unless_db
dump_vars

export cfg=/etc/murano/murano.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/murano/config-rabbitmq.sh
/opt/harbor/murano/config-database.sh
/opt/harbor/murano/config-keystone.sh
/opt/harbor/murano/config-rabbitmq-murano.sh

################################################################################
echo "${OS_DISTRO}: CONFIG: General"
################################################################################
crudini --set $cfg DEFAULT verbose "${DEBUG}"
crudini --set $cfg DEFAULT debug "${DEBUG}"
#crudini --set $cfg DEFAULT notification_driver messagingv2






################################################################################
echo "${OS_DISTRO}: CONFIG: networking"
################################################################################
crudini --set $cfg networking default_dns "${MURANO_DNS}"
# Incase we need to move to id's
#EXTERNAL_NET_ID=$(neutron net-show "${EXTERNAL_NET_NAME}" -f value -c id)
crudini --set $cfg networking external_network "${EXTERNAL_NET_NAME}"
crudini --set $cfg networking router_name "${MURANO_ROUTER_NAME}"
crudini --set $cfg networking env_ip_template "172.16.0.0"


################################################################################
echo "${OS_DISTRO}: CONFIG: API Host"
################################################################################
crudini --set $cfg murano url "https://murano.${OS_DOMAIN}"
