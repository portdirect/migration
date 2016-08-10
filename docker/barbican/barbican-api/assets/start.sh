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
. /opt/harbor/config-barbican.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting api to listen on 127.0.0.1:8080"
################################################################################
export cfg=/etc/barbican/barbican.conf
crudini --set $cfg DEFAULT bind_host "127.0.0.1"
crudini --set $cfg DEFAULT bind_port "8080"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up KRA"
################################################################################
mkdir -p /etc/barbican
cat /etc/os-kra/kra-agent-pem | sed 's/\\n/\n/g' > /etc/barbican/kra-agent.pem
#crudini --set $cfg DEFAULT debug "True"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/gunicorn -c /etc/barbican/gunicorn-config.py --paste /etc/barbican/barbican-api-paste.ini
