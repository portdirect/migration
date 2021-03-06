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
. /opt/harbor/config-nova-api.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Nova TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
#exec httpd -D FOREGROUND


cfg=/etc/nova/nova.conf
crudini --set $cfg DEFAULT use_neutron "True"
crudini --set $cfg DEFAULT debug "True"
crudini --set $cfg DEFAULT ssl_only "True"
crudini --set $cfg DEFAULT ssl_cert_file "/etc/pki/tls/certs/ca.crt"
crudini --set $cfg DEFAULT ssl_key_file "/etc/pki/tls/private/ca.key"
crudini --set $cfg ssl cert_file "/etc/pki/tls/certs/ca.crt"
crudini --set $cfg ssl key_file "/etc/pki/tls/private/ca.key"
crudini --set $cfg DEFAULT enabled_ssl_apis "osapi_compute"
nova-api-os-compute --debug --verbose --config-file /etc/nova/nova.conf
