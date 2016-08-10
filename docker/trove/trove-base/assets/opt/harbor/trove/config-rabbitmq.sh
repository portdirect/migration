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
check_required_vars cfg RABBITMQ_SERVICE_HOST TROVE_RABBITMQ_USER TROVE_RABBITMQ_PASS


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg oslo_messaging_rabbit rabbit_use_ssl "False"

crudini --set $cfg oslo_messaging_rabbit rabbit_host "trove-messaging.${OS_DOMAIN}"
crudini --set $cfg oslo_messaging_rabbit rabbit_port "5676"
crudini --set $cfg oslo_messaging_rabbit rabbit_hosts "trove-messaging.${OS_DOMAIN}:5676"

crudini --set $cfg oslo_messaging_rabbit rabbit_userid ${TROVE_RABBITMQ_USER}
crudini --set $cfg oslo_messaging_rabbit rabbit_password "${TROVE_RABBITMQ_PASS}"
