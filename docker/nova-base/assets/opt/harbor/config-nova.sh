#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

OPENSTACK_SUBCOMPONENT=common-config
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh



: ${ADMIN_TENANT_NAME:="admin"}
: ${NETWORK_MANAGER:="nova"}
: ${FLAT_NETWORK:="eth1"}
: ${PUBLIC_NETWORK:="eth0"}
: ${ENABLED_APIS:="ec2,osapi_compute,metadata"}
: ${METADATA_HOST:="127.0.0.1"}
: ${NEUTRON_SERVER_SERVICE_PORT:="9696"}
: ${NEUTRON_SHARED_SECRET:="sharedsecret"}
: ${SERVICE_TENANT_NAME:="services"}
: ${DEFAULT_REGION:="HarborOS"}
: ${DEBUG_LOGGING:="False"}
: ${VERBOSE_LOGGING:="False"}
: ${MECHANISM_DRIVERS:="openvswitch,l2population"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars MECHANISM_DRIVERS \
                    NEUTRON_KEYSTONE_USER NEUTRON_KEYSTONE_PASSWORD \
                    SERVICE_TENANT_NAME DEFAULT_REGION BARBICAN_API_SERVICE_HOST




export cfg=/etc/nova/nova.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: General"
################################################################################
crudini --set $cfg DEFAULT rootwrap_config "/etc/nova/rootwrap.conf"
crudini --set $cfg DEFAULT service_down_time "60"
crudini --set $cfg DEFAULT use_forwarded_for "False"
crudini --set $cfg DEFAULT instances_path "/var/lib/nova/instances"
crudini --set $cfg DEFAULT lock_path "/var/lib/nova/tmp"
crudini --set $cfg DEFAULT state_path "/var/lib/nova"
crudini --set $cfg DEFAULT log_dir "/var/log/nova"
crudini --set $cfg DEFAULT keys_path "\$state_path/keys"
# This is not created by openstack-nova packaging
mkdir -p /var/lib/nova/tmp


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
/opt/harbor/nova/config-rabbitmq.sh
/opt/harbor/nova/config-database.sh
/opt/harbor/nova/config-database-api.sh
/opt/harbor/nova/config-keystone.sh
/opt/harbor/nova/config-neutron.sh
/opt/harbor/nova/config-glance.sh
/opt/harbor/nova/config-cinder.sh
/opt/harbor/nova/config-ceilometer.sh
/opt/harbor/nova/config-hypervisor.sh
/opt/harbor/nova/config-conductor.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Instance Domain"
################################################################################
crudini --set $cfg DEFAULT dhcp_domain "in.${OS_DOMAIN}"
crudini --set $cfg DEFAULT multi_instance_display_name_template "%(uuid)s-%(count)d"
crudini --set $cfg DEFAULT instance_name_template "instance-%08x"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Notifications"
################################################################################
crudini --set $cfg oslo_messaging_notifications topics "notifications,notifications_dns"
crudini --set $cfg DEFAULT notify_on_state_change "vm_and_task_state"
crudini --set $cfg DEFAULT instance_usage_audit_period "hour"
crudini --set $cfg oslo_messaging_notifications driver "messagingv2"
#sed -i '/[oslo_messaging_notifications]/a driver = messaging' $cfg



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: API Config"
################################################################################
crudini --set $cfg DEFAULT enabled_apis "${ENABLED_APIS}"
crudini --set $cfg DEFAULT ec2_listen "0.0.0.0"
crudini --set $cfg DEFAULT osapi_compute_listen "0.0.0.0"
crudini --set $cfg DEFAULT osapi_compute_workers "8"
crudini --set $cfg osapi_v3 enabled "True"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Metadata Server Config"
################################################################################
crudini --set $cfg DEFAULT metadata_host "${METADATA_HOST}"
crudini --set $cfg DEFAULT metadata_listen "0.0.0.0"
crudini --set $cfg DEFAULT metadata_workers "8"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Scheduler"
################################################################################
crudini --set $cfg DEFAULT scheduler_default_filters "RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,CoreFilter"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Logging"
################################################################################
crudini --set $cfg DEFAULT debug "${DEBUG}"
crudini --set $cfg DEFAULT verbose "${DEBUG}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ENCRYPTION"
################################################################################
crudini --set $cfg keymgr api_class "nova.keymgr.barbican.BarbicanKeyManager"
crudini --set $cfg keymgr encryption_auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}/v3"
crudini --set $cfg barbican  endpoint_template "${KEYSTONE_AUTH_PROTOCOL}://${BARBICAN_API_SERVICE_HOST}/v1"
crudini --set $cfg barbican os_region_name "${DEFAULT_REGION}"
crudini --set $cfg certificates barbican_auth "barbican_acl_auth"
crudini --set $cfg certificates cert_manager_type "barbican"
