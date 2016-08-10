#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=common-config
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
: ${DEFAULT_REGION:="HarborOS"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Checking Env"
################################################################################


export cfg=/etc/manila/manila.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/manila/config-keystone.sh
. /opt/harbor/manila/config-keystone-nova.sh
. /opt/harbor/manila/config-keystone-neutron.sh
. /opt/harbor/manila/config-keystone-cinder.sh
. /opt/harbor/manila/config-database.sh
. /opt/harbor/manila/config-rabbitmq.sh

crudini --set $cfg DEFAULT auth_strategy "keystone"
crudini --set $cfg DEFAULT debug "True"
crudini --set $cfg DEFAULT scheduler_driver "manila.scheduler.filter_scheduler.FilterScheduler"
crudini --set $cfg DEFAULT share_name_template "share-%s"
crudini --set $cfg DATABASE max_pool_size "40"
crudini --set $cfg DEFAULT api_paste_config "/etc/manila/api-paste.ini"
crudini --set $cfg DEFAULT rootwrap_config "/etc/manila/rootwrap.conf"
crudini --set $cfg DEFAULT osapi_share_extension "manila.api.contrib.standard_extensions"
crudini --set $cfg DEFAULT state_path "/var/lib/os-manila"
crudini --set $cfg DEFAULT default_share_type "default"

crudini --set $cfg DEFAULT enabled_share_protocols "NFS,CIFS"

crudini --set $cfg oslo_concurrency lock_path "/var/lock/manila"

crudini --set $cfg DEFAULT wsgi_keep_alive "False"

crudini --set $cfg DEFAULT lvm_share_volume_group "lvm-shares"

# Set the replica_state_update_interval
crudini --set $cfg DEFAULT replica_state_update_interval "300"

# if is_service_enabled neutron; then
#     configure_auth_token_middleware $MANILA_CONF neutron $MANILA_AUTH_CACHE_DIR neutron
# fi
# if is_service_enabled nova; then
#     configure_auth_token_middleware $MANILA_CONF nova $MANILA_AUTH_CACHE_DIR nova
# fi
# if is_service_enabled cinder; then
#     configure_auth_token_middleware $MANILA_CONF cinder $MANILA_AUTH_CACHE_DIR cinder
# fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting MANILA_NET_ID"
################################################################################
MANILA_NET_ID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/admin_network_id)"
check_required_vars MANILA_NET_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting MANILA_NET_ID"
################################################################################
MANILA_SUBNET_ID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/admin_subnet_id)"
check_required_vars MANILA_SUBNET_ID


# configure_default_backends - configures default Manila backends with generic driver.
function configure_default_backends {
    # Configure two default backends with generic drivers onboard
    for group_name in $MANILA_BACKEND1_CONFIG_GROUP_NAME ; do
        crudini --set $cfg $group_name share_driver "manila.share.drivers.generic.GenericShareDriver"
        if [ "$MANILA_BACKEND1_CONFIG_GROUP_NAME" == "$group_name" ]; then
            crudini --set $cfg $group_name share_backend_name $MANILA_SHARE_BACKEND1_NAME
        fi
        crudini --set $cfg $group_name path_to_public_key "/etc/os-ssh/cirt"
        crudini --set $cfg $group_name path_to_private_key "/etc/os-ssh/key"
        crudini --set $cfg $group_name service_image_name "Manila-Server"
        crudini --set $cfg $group_name service_instance_user "manila"
        crudini --set $cfg $group_name driver_handles_share_servers "True"
        crudini --set $cfg $group_name admin_network_id "${MANILA_NET_ID}"
        crudini --set $cfg $group_name admin_subnet_id "${MANILA_SUBNET_ID}"
        crudini --set $cfg $group_name interface_driver "manila.network.linux.interface.OVSInterfaceDriver"
        crudini --set $cfg $group_name cinder_volume_type "LVMVolume"
        crudini --set $cfg $group_name connect_share_server_to_tenant_network "False"


    done
}


# Note: set up config group does not mean that this backend will be enabled.
# To enable it, specify its name explicitly using "enabled_share_backends" opt.
MANILA_BACKEND1_CONFIG_GROUP_NAME="default-backend"
MANILA_SHARE_BACKEND1_NAME="default"
configure_default_backends

crudini --set $cfg DEFAULT enabled_share_backends "$MANILA_BACKEND1_CONFIG_GROUP_NAME"
crudini --set $cfg DEFAULT manila_service_keypair_name "manila-service"
