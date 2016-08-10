#!/bin/bash
set -o errexit
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


export cfg=/etc/barbican/barbican.conf
export cfg_api_paste=/etc/barbican/barbican-api-paste.ini
export cfg_vassals=/etc/barbican/vassals/barbican-api.ini
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SETUP"
################################################################################
/opt/harbor/barbican/config-database.sh
/opt/harbor/barbican/config-api.sh
/opt/harbor/barbican/config-rabbitmq.sh
/opt/harbor/barbican/config-keystone.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DOGTAG"
################################################################################
crudini --set $cfg dogtag_plugin pem_path "/etc/barbican/kra-agent.pem"
# Barbican runs in containers registered with FreeIPA..
crudini --set $cfg dogtag_plugin dogtag_host "$(crudini --get /etc/ipa/default.conf global server)"
crudini --set $cfg dogtag_plugin dogtag_port "8443"

crudini --set $cfg secretstore enabled_secretstore_plugins "dogtag_crypto"
crudini --set $cfg certificate enabled_certificate_plugins "dogtag"
