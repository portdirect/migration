#!/bin/bash
set -e
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
. /opt/harbor/config-nova.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars NOVA_DB_NAME NOVA_DB_USER NOVA_DB_PASSWORD OS_DOMAIN



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${NOVA_DB_NAME}


cfg=/etc/nova/nova.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: VNC"
################################################################################
# Listen on all interfaces on port $NOVA_NOVNC_PROXY_PORT for incoming novnc
# requests.
# The base_url is given to clients to connect to, like Horizon, so this could
# very well be fancy DNS name.
crudini --set $cfg DEFAULT console_allowed_origins "api.$OS_DOMAIN"
crudini --set $cfg DEFAULT vncserver_listen "0.0.0.0"
crudini --set $cfg DEFAULT novncproxy_host "0.0.0.0"
crudini --set $cfg DEFAULT novncproxy_port "6080"


CONTAINER_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
crudini --set $cfg DEFAULT vncserver_proxyclient_address "${CONTAINER_IP}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSL"
################################################################################
TLS_HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt
crudini --set $cfg DEFAULT cert "/etc/pki/tls/certs/ca.crt"
crudini --set $cfg DEFAULT key "/etc/pki/tls/private/ca.key"
crudini --set $cfg DEFAULT ssl_only "true"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /usr/bin/nova-novncproxy nova
