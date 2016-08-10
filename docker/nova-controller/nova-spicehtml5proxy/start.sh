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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Serial"
################################################################################
crudini --set $cfg DEFAULT console_allowed_origins "api.$OS_DOMAIN"
crudini --set $cfg DEFAULT vnc_enabled "False"
crudini --set $cfg DEFAULT web "/usr/share/spice-html5"

crudini --set $cfg spice html5proxy_base_url "${KEYSTONE_AUTH_PROTOCOL}://spice.$OS_DOMAIN/spice_auto.html"
crudini --set $cfg spice enabled "True"
crudini --set $cfg spice agent_enabled "True"
crudini --set $cfg spice html5proxy_host "0.0.0.0"
crudini --set $cfg spice html5proxy_port "6082"

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
exec su -s /bin/sh -c "exec /usr/bin/nova-spicehtml5proxy" nova
