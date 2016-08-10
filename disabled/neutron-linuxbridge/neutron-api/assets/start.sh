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
. /opt/harbor/config-neutron.sh
. /opt/harbor/config-neutron-api.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars NEUTRON_DB_NAME NEUTRON_DB_USER NEUTRON_DB_PASSWORD


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${NEUTRON_DB_NAME}
fail_unless_os_service_running keystone


# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching without TLS"
# ################################################################################
# exec /usr/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Nova TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' | sed 's/\\r$//g'  > /etc/pki/tls/certs/ca.crt
cat /etc/os-ssl/ca | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/certs/ca-auth.crt
core_cfg=/etc/neutron/neutron.conf
crudini --set $core_cfg DEFAULT use_ssl "True"
crudini --set $core_cfg DEFAULT ssl_cert_file "/etc/pki/tls/certs/ca.crt"
crudini --set $core_cfg DEFAULT ssl_key_file "/etc/pki/tls/private/ca.key"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec /usr/bin/neutron-server --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini
