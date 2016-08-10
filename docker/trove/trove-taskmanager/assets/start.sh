#!/bin/bash
set -o errexit
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

tail -f /dev/null
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/config-trove.sh
: ${DEFAULT_REGION:="HarborOS"}

export cfg=/etc/trove/trove-taskmanager.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg KEYSTONE_AUTH_PROTOCOL KEYSTONE_PUBLIC_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/trove/config-database.sh
. /opt/harbor/trove/config-rabbitmq.sh

#crudini --set $cfg DEFAULT nova_compute_endpoint_type "publicURL"
crudini --set $cfg DEFAULT taskmanager_manager "trove.taskmanager.manager.Manager"

crudini --set $cfg DEFAULT nova_proxy_admin_user "${TROVE_KEYSTONE_USER}"
source openrc
export OS_CACERT=/etc/pki/tls/certs/ca-bundle.crt
mkdir -p /usr/lib/python2.7/site-packages/requests
cat /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem >> /usr/lib/python2.7/site-packages/requests/cacert.pem
SERVICE_TENANT_ID=$(openstack project show --domain default ${SERVICE_TENANT_NAME} -f value -c id)
crudini --set $cfg DEFAULT nova_proxy_admin_tenant_id "${SERVICE_TENANT_ID}"
crudini --set $cfg DEFAULT nova_proxy_admin_tenant_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg DEFAULT nova_proxy_admin_pass "${TROVE_KEYSTONE_PASSWORD}"
crudini --set $cfg DEFAULT trove_auth_url "https://keystone.${OS_DOMAIN}/v3"
crudini --set $cfg DEFAULT os_region_name "${DEFAULT_REGION}"
crudini --set $cfg DEFAULT nova_compute_url "https://nova.${OS_DOMAIN}/v2"
crudini --set $cfg DEFAULT cinder_url "https://cinder.${OS_DOMAIN}/v2"
crudini --set $cfg DEFAULT neutron_url "https://neutron.${OS_DOMAIN}/"
crudini --set $cfg DEFAULT region "${DEFAULT_REGION}"
crudini --set $cfg DEFAULT cinder_volume_type "GlusterFS"
crudini --set $cfg DEFAULT use_heat "True"
crudini --set $cfg DEFAULT use_nova_server_config_drive "False"
crudini --set $cfg DEFAULT network_driver "trove.network.neutron.NeutronDriver"
crudini --set $cfg DEFAULT trove_volume_support "False"
crudini --set $cfg DEFAULT device_path ""



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting TROVE_NET_ID"
################################################################################
TROVE_NET_ID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/management_network_id)"
check_required_vars TROVE_NET_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Networking COnfig"
################################################################################
crudini --set $cfg DEFAULT network_label_regex ".*"
crudini --set $cfg DEFAULT ip_regex ".*"
crudini --set $cfg DEFAULT blacklist_regex "^10.0.1.*"
crudini --set $cfg DEFAULT default_neutron_networks "${TROVE_NET_ID}"
crudini --set $cfg DEFAULT network_driver "trove.network.neutron.NeutronDriver"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Adding IPA CA Cirt to templates"
################################################################################
find /usr/lib/python2.7/site-packages/trove/templates -type f -exec bash -c 'sed -i "s,{{IPA_CA_CRT_REPLACED_BY_TROVE_TASKMANAGER_LAUNCH_SCRIPT}},$(cat /etc/pki/tls/certs/ca-bundle.crt | base64 --wrap 0)", "$0"' {} \;



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Censuring Permissions Are Correct"
################################################################################
chown -R trove /usr/lib/python2.7/site-packages/trove/templates



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
exec su -s /bin/sh -c "exec /usr/bin/trove-taskmanager --config-file /etc/trove/trove.conf --config-file /etc/trove/trove-taskmanager.conf --debug" trove
