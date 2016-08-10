#!/bin/sh
set -e
MARIADB_SERVICE_HOST=${MASTER_IP}
MEMCACHED_SERVICE_HOST=${MASTER_IP}
KEYSTONE_SERVICE_HOST=${MASTER_IP}
RABBITMQ_SERVICE_HOST=${MASTER_IP}
GLANCE_SERVICE_HOST=${MASTER_IP}
NEUTRON_SERVICE_HOST=${MASTER_IP}
OVN_NORTHD_IP=${MASTER_IP}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}



DB_NAME=${OS_COMP}
DB_USER=${OS_COMP}
DB_PASSWORD=${DB_ROOT_PASSWORD}
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For DB"
################################################################################
wait-mysql

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Public Keystone"
################################################################################
wait-http $KEYSTONE_SERVICE_HOST:5000

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Public Nova"
################################################################################
wait-http $NOVA_SERVICE_HOST:8774




cfg=/etc/nova/nova.conf
crudini --set $cfg DEFAULT lock_path "/var/lib/nova/lock"
crudini --set $cfg DEFAULT vif_plugging_timeout "300"
crudini --set $cfg DEFAULT vif_plugging_is_fatal "True"
crudini --set $cfg DEFAULT use_neutron "True"
crudini --set $cfg DEFAULT firewall_driver "nova.virt.firewall.NoopFirewallDriver"
#crudini --set $cfg DEFAULT compute_driver "libvirt.LibvirtDriver"


crudini --set $cfg DEFAULT compute_driver "novadocker.virt.docker.DockerDriver"
crudini --set $cfg docker host_url "unix:///var/run/docker.sock"
crudini --set $cfg docker privileged "False"


crudini --set $cfg DEFAULT default_ephemeral_format "ext4"
crudini --set $cfg DEFAULT dhcpbridge_flagfile "/etc/nova/nova-dhcpbridge.conf"
crudini --set $cfg DEFAULT graceful_shutdown_timeout "5"
crudini --set $cfg DEFAULT metadata_workers "2"
crudini --set $cfg DEFAULT osapi_compute_workers "2"
crudini --set $cfg DEFAULT transport_url "rabbit://guest:guest@${RABBITMQ_SERVICE_HOST}:5672/"
crudini --set $cfg DEFAULT logging_exception_prefix "%(color)s%(asctime)s.%(msecs)03d TRACE %(name)s %(instance)s"
crudini --set $cfg DEFAULT logging_debug_format_suffix "from (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d"
crudini --set $cfg DEFAULT logging_default_format_string "%(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [-%(color)s] %(instance)s%(color)s%(message)s"
crudini --set $cfg DEFAULT logging_context_format_string "%(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [%(request_id)s %(user_name)s %(project_name)s%(color)s] %(instance)s%(color)s%(message)s"
crudini --set $cfg DEFAULT force_config_drive "False"
crudini --set $cfg DEFAULT instances_path "/var/lib/nova"
crudini --set $cfg DEFAULT state_path "/var/lib/nova"
crudini --set $cfg DEFAULT enabled_apis "osapi_compute,metadata"
crudini --set $cfg DEFAULT my_ip "${MASTER_IP}"

crudini --set $cfg DEFAULT metadata_listen "0.0.0.0"
crudini --set $cfg DEFAULT osapi_compute_listen "0.0.0.0"
crudini --set $cfg DEFAULT s3_port "3333"
crudini --set $cfg DEFAULT s3_listen "0.0.0.0"
crudini --set $cfg DEFAULT s3_host "${MASTER_IP}"

crudini --set $cfg DEFAULT instance_name_template "instance-%08x"



crudini --set $cfg DEFAULT default_floating_pool "public"
crudini --set $cfg DEFAULT force_dhcp_release "True"
crudini --set $cfg DEFAULT scheduler_default_filters "RetryFilter,AvailabilityZoneFilter,RamFilter,DiskFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter,SameHostFilter,DifferentHostFilter"
crudini --set $cfg DEFAULT scheduler_driver "filter_scheduler"
crudini --set $cfg DEFAULT rootwrap_config "/etc/nova/rootwrap.conf"
crudini --set $cfg DEFAULT allow_resize_to_same_host "True"
crudini --set $cfg DEFAULT debug "True"

crudini --set $cfg wsgi api_paste_config "/etc/nova/api-paste.ini"


crudini --set $cfg database connection "mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DB_NAME}?charset=utf8"
crudini --set $cfg api_database connection "mysql+pymysql://${DB_USER}_api:${DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DB_NAME}_api?charset=utf8"



crudini --set $cfg privsep_osbrick helper_command "sudo nova-rootwrap \$rootwrap_config privsep-helper --config-file /etc/nova/nova.conf"

crudini --set $cfg vif_plug_ovs_privileged helper_command "sudo nova-rootwrap $rootwrap_config privsep-helper --config-file /etc/nova/nova.conf"

crudini --set $cfg vif_plug_linux_bridge_privileged helper_command "sudo nova-rootwrap $rootwrap_config privsep-helper --config-file /etc/nova/nova.conf"

crudini --set $cfg keystone_authtoken memcached_servers "${MEMCACHED_SERVICE_HOST}:11211"
crudini --set $cfg keystone_authtoken auth_uri "http://${KEYSTONE_SERVICE_HOST}:5000"
crudini --set $cfg keystone_authtoken project_domain_name "default"
crudini --set $cfg keystone_authtoken project_name "service"
crudini --set $cfg keystone_authtoken user_domain_name "default"
crudini --set $cfg keystone_authtoken password "password"
crudini --set $cfg keystone_authtoken username "nova"
crudini --set $cfg keystone_authtoken auth_url "http://${KEYSTONE_SERVICE_HOST}:35357/v3"
crudini --set $cfg keystone_authtoken auth_type "password"
crudini --set $cfg keystone_authtoken auth_version "v3"
crudini --set $cfg keystone_authtoken signing_dir "/var/cache/neutron"
crudini --set $cfg keystone_authtoken cafile "/opt/stack/data/ca-bundle.pem"
crudini --set $cfg keystone_authtoken region_name "RegionOne"


crudini --set $cfg oslo_concurrency lock_path "/opt/stack/data/nova"


crudini --set $cfg vnc xvpvncproxy_host "0.0.0.0"
crudini --set $cfg vnc novncproxy_host "0.0.0.0"
crudini --set $cfg vnc vncserver_proxyclient_address "127.0.0.1"
crudini --set $cfg vnc vncserver_listen "127.0.0.1"
crudini --set $cfg vnc enabled "true"
crudini --set $cfg vnc xvpvncproxy_base_url "http://${MASTER_IP}:6081/console"
crudini --set $cfg vnc novncproxy_base_url "http://${MASTER_IP}:6080/vnc_auto.html"


crudini --set $cfg spice enabled "false"
crudini --set $cfg spice html5proxy_base_url "http://${MASTER_IP}:6082/spice_auto.html"


crudini --set $cfg glance api_servers "http://${GLANCE_SERVICE_HOST}:9292"


crudini --set $cfg conductor workers "2"

crudini --set $cfg cinder os_region_name "RegionOne"


crudini --set $cfg libvirt inject_partition "-2"
crudini --set $cfg libvirt live_migration_uri "qemu+ssh://ubuntu@%s/system"
crudini --set $cfg libvirt use_usb_tablet "False"
crudini --set $cfg libvirt cpu_mode "none"
crudini --set $cfg libvirt virt_type "qemu"


crudini --set $cfg neutron service_metadata_proxy "True"
crudini --set $cfg neutron url "http://${NEUTRON_SERVICE_HOST}:9696"

crudini --set $cfg neutron memcached_servers "${MEMCACHED_SERVICE_HOST}:11211"
crudini --set $cfg neutron auth_uri "http://${KEYSTONE_SERVICE_HOST}:5000"
crudini --set $cfg neutron project_domain_name "default"
crudini --set $cfg neutron project_name "service"
crudini --set $cfg neutron user_domain_name "default"
crudini --set $cfg neutron password "password"
crudini --set $cfg neutron username "neutron"
crudini --set $cfg neutron auth_url "http://${KEYSTONE_SERVICE_HOST}:35357/v3"
crudini --set $cfg neutron auth_type "password"
crudini --set $cfg neutron auth_version "v3"
crudini --set $cfg neutron signing_dir "/var/cache/nova"
crudini --set $cfg neutron cafile "/opt/stack/data/ca-bundle.pem"
crudini --set $cfg neutron region_name "RegionOne"


crudini --set $cfg key_manager fixed_key "738b63e7074a1efb52551902fcf2d2c6ab455d4e1d7189970360ae4a852c6778"



exec nova-cert --config-file $cfg --debug
