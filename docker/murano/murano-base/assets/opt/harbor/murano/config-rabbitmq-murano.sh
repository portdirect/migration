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
check_required_vars cfg MURANO_RABBITMQ_USER MURANO_RABBITMQ_PASS


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connection"
################################################################################
crudini --set $cfg rabbitmq ssl "False"

crudini --set $cfg rabbitmq host "murano-messaging.${OS_DOMAIN}"
crudini --set $cfg rabbitmq port "5672"

crudini --set $cfg rabbitmq login ${MURANO_RABBITMQ_USER}
crudini --set $cfg rabbitmq password "${MURANO_RABBITMQ_PASS}"

crudini --set $cfg rabbitmq virtual_host "/"
