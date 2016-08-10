#!/bin/bash
set -e
OPENSTACK_CONFIG_COMPONENT=lbaas
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Config lbaas"
################################################################################
crudini --set $lbass_cfg service_providers service_provider 'LOADBALANCER:Haproxy:neutron_lbaas.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default'

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_CONFIG_COMPONENT}: Keystone"
################################################################################
crudini --set $lbass_cfg service_auth auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
crudini --set $lbass_cfg service_auth admin_tenant_name = "${SERVICE_TENANT_NAME}"
crudini --set $lbass_cfg service_auth admin_user "${NEUTRON_KEYSTONE_USER}"
crudini --set $lbass_cfg service_auth admin_password = "${NEUTRON_KEYSTONE_PASSWORD}"
crudini --set $lbass_cfg service_auth admin_user_domain = "Default"
crudini --set $lbass_cfg service_auth admin_project_domain = "Default"
