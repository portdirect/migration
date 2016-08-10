#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=rabbitmq
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg RABBITMQ_SERVICE_HOST RABBITMQ_USER RABBITMQ_PASS


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg oslo_messaging_rabbit rabbit_use_ssl "True"

crudini --set $cfg oslo_messaging_rabbit rabbit_host "messaging.${OS_DOMAIN}"
crudini --set $cfg oslo_messaging_rabbit rabbit_port "5672"
crudini --set $cfg oslo_messaging_rabbit rabbit_hosts "messaging.${OS_DOMAIN}:5672"

crudini --set $cfg oslo_messaging_rabbit rabbit_userid ${RABBITMQ_USER}
crudini --set $cfg oslo_messaging_rabbit rabbit_password "${RABBITMQ_PASS}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
crudini --set $cfg oslo_messaging_rabbit kombu_ssl_version "TLSv1_2"
crudini --set $cfg oslo_messaging_rabbit kombu_ssl_keyfile "/etc/os-ssl-messaging/messaging.key"
crudini --set $cfg oslo_messaging_rabbit kombu_ssl_certfile "/etc/os-ssl-messaging/messaging.crt"
crudini --set $cfg oslo_messaging_rabbit kombu_ssl_ca_certs "/etc/os-ssl-messaging/messaging-ca.crt"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
crudini --set $cfg oslo_messaging_rabbit rabbit_virtual_host /
crudini --set $cfg oslo_messaging_rabbit rabbit_ha_queues False
crudini --set $cfg oslo_messaging_rabbit amqp_durable_queues "False"
