#!/bin/sh
set -e
MARIADB_SERVICE_HOST=${MARIADB_SERVICE_HOST}
MEMCACHED_SERVICE_HOST=${MEMCACHED_SERVICE_HOST}
KEYSTONE_SERVICE_HOST=${KEYSTONE_SERVICE_HOST}
RABBITMQ_SERVICE_HOST=${RABBITMQ_SERVICE_HOST}
NEUTRON_SERVICE_HOST=${RABBITMQ_SERVICE_HOST}
OVS_NB_DB_IP=${OVS_NB_DB_IP}
OVS_SB_DB_IP=${OVS_SB_DB_IP}
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Public Neutron"
################################################################################
wait-http $NEUTRON_SERVICE_HOST:9696






################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing any existing router namespaces"
################################################################################
ip netns list | grep qrouter | while read -r line ; do
  ip netns delete $line
done
ip netns list | grep qrouter | while read -r line ; do
  ip netns delete $line
done



cfg=/etc/neutron/neutron.conf
cfg_ml2=/etc/neutron/plugins/ml2/ml2_conf.ini
cfg_l3=/etc/neutron/l3_agent.ini
cfg_lbaas=/etc/neutron/neutron_lbaas.conf
cfg_lbaas_haproxy=/etc/neutron/services/loadbalancer/haproxy/lbaas_agent.ini


crudini --set $cfg DEFAULT debug "True"
crudini --set $cfg DEFAULT use_syslog "False"
crudini --set $cfg DEFAULT logging_exception_prefix "%(color)s%(asctime)s.%(msecs)03d TRACE %(name)s %(instance)s"
crudini --set $cfg DEFAULT logging_debug_format_suffix "from (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d"
crudini --set $cfg DEFAULT logging_default_format_string "%(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [-%(color)s] %(instance)s%(color)s%(message)s"
crudini --set $cfg DEFAULT logging_context_format_string "%(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [%(request_id)s %(user_name)s %(project_id)s%(color)s] %(instance)s%(color)s%(message)s"

crudini --set $cfg DEFAULT bind_host "0.0.0.0"
crudini --set $cfg DEFAULT auth_strategy "keystone"

crudini --set $cfg DEFAULT global_physnet_mtu "1300"
crudini --set $cfg DEFAULT allow_overlapping_ips "True"

crudini --set $cfg DEFAULT api_workers "2"
crudini --set $cfg DEFAULT state_path "/var/lib/${OS_COMP}/state"
crudini --set $cfg DEFAULT core_plugin "neutron.plugins.ml2.plugin.Ml2Plugin"
crudini --set $cfg DEFAULT service_plugins "neutron.services.l3_router.l3_router_plugin.L3RouterPlugin,neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2"

crudini --set $cfg DEFAULT notify_nova_on_port_data_changes "True"
crudini --set $cfg DEFAULT notify_nova_on_port_status_changes "True"


crudini --set $cfg database connection "mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DB_NAME}?charset=utf8"

crudini --set $cfg keystone_authtoken memcached_servers "${MEMCACHED_SERVICE_HOST}:11211"
crudini --set $cfg keystone_authtoken auth_uri "http://${KEYSTONE_SERVICE_HOST}:5000"
crudini --set $cfg keystone_authtoken project_domain_name "default"
crudini --set $cfg keystone_authtoken project_name "service"
crudini --set $cfg keystone_authtoken user_domain_name "default"
crudini --set $cfg keystone_authtoken password "password"
crudini --set $cfg keystone_authtoken username "neutron"
crudini --set $cfg keystone_authtoken auth_url "http://${KEYSTONE_SERVICE_HOST}:35357/v3"
crudini --set $cfg keystone_authtoken auth_type "password"
crudini --set $cfg keystone_authtoken auth_version "v3"
crudini --set $cfg keystone_authtoken signing_dir "/var/cache/neutron"
crudini --set $cfg keystone_authtoken cafile "/opt/stack/data/ca-bundle.pem"
crudini --set $cfg keystone_authtoken region_name "RegionOne"

crudini --set $cfg nova memcached_servers "${MEMCACHED_SERVICE_HOST}:11211"
crudini --set $cfg nova auth_uri "http://${KEYSTONE_SERVICE_HOST}:5000"
crudini --set $cfg nova project_domain_name "default"
crudini --set $cfg nova project_name "service"
crudini --set $cfg nova user_domain_name "default"
crudini --set $cfg nova password "password"
crudini --set $cfg nova username "nova"
crudini --set $cfg nova auth_url "http://${KEYSTONE_SERVICE_HOST}:35357/v3"
crudini --set $cfg nova auth_type "password"
crudini --set $cfg nova auth_version "v3"
crudini --set $cfg nova signing_dir "/var/cache/neutron"
crudini --set $cfg nova cafile "/opt/stack/data/ca-bundle.pem"
crudini --set $cfg nova region_name "RegionOne"

crudini --set $cfg oslo_policy policy_file "/etc/neutron/policy.json"

crudini --set $cfg service_auth auth_version "2"
crudini --set $cfg service_auth admin_password "password"
crudini --set $cfg service_auth admin_user "admin"
crudini --set $cfg service_auth admin_tenant_name "admin"
crudini --set $cfg service_auth auth_url "http://${KEYSTONE_SERVICE_HOST}:5000/v2.0"

crudini --set $cfg DEFAULT transport_url "rabbit://guest:guest@${RABBITMQ_SERVICE_HOST}:5672/"

crudini --set $cfg agent root_helper_daemon "sudo /usr/bin/neutron-rootwrap-daemon /etc/neutron/rootwrap.conf"
crudini --set $cfg agent root_helper "sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf"

crudini --set $cfg oslo_concurrency lock_path "/var/lib/neutron/lock"

crudini --set $cfg QUOTAS.default_quota "-1"
crudini --set $cfg QUOTAS.quota_driver "neutron.db.quota.driver.DbQuotaDriver"
crudini --set $cfg QUOTAS.quota_floatingip "50"
crudini --set $cfg QUOTAS.quota_health_monitor "-1"
crudini --set $cfg QUOTAS.quota_healthmonitor "-1"
crudini --set $cfg QUOTAS.quota_listener "-1"
crudini --set $cfg QUOTAS.quota_loadbalancer "50"
crudini --set $cfg QUOTAS.quota_member "-1"
crudini --set $cfg QUOTAS.quota_network "100"
crudini --set $cfg QUOTAS.quota_pool "100"
crudini --set $cfg QUOTAS.quota_port "500"
crudini --set $cfg QUOTAS.quota_rbac_policy "10"
crudini --set $cfg QUOTAS.quota_router "10"
crudini --set $cfg QUOTAS.quota_security_group "100"
crudini --set $cfg QUOTAS.quota_security_group_rule "1000"
crudini --set $cfg QUOTAS.quota_subnet "100"
crudini --set $cfg QUOTAS.quota_vip "100"
crudini --set $cfg QUOTAS.track_quota_usage "True"

crudini --set $cfg_ml2 ml2 tenant_network_types "geneve"
crudini --set $cfg_ml2 ml2 extension_drivers "port_security"
crudini --set $cfg_ml2 ml2 type_drivers "local,flat,vlan,geneve"
crudini --set $cfg_ml2 ml2 mechanism_drivers "ovn,logger"
crudini --set $cfg_ml2 ml2 overlay_ip_version "4"

crudini --set $cfg_ml2 ml2_type_flat flat_networks "*"

crudini --set $cfg_ml2 ml2_type_vxlan vxlan_group ""
crudini --set $cfg_ml2 ml2_type_vxlan vni_ranges "1:1000"

crudini --set $cfg_ml2 ml2_type_geneve vni_ranges "1:65536"
crudini --set $cfg_ml2 ml2_type_geneve max_header_size "38"

crudini --set $cfg_ml2 ml2_type_gre tunnel_id_ranges "1:1000"

crudini --set $cfg_ml2 securitygroup enable_security_group "True"
crudini --set $cfg_ml2 securitygroup enable_ipset "True"

crudini --set $cfg_ml2 ovn neutron_sync_mode "repair"
crudini --set $cfg_ml2 ovn ovn_sb_connection "tcp:${OVS_SB_DB_IP}:6642"
crudini --set $cfg_ml2 ovn ovn_nb_connection "tcp:${OVS_NB_DB_IP}:6641"
crudini --set $cfg_ml2 ovn ovn_l3_mode "False"
crudini --set $cfg_ml2 ovn ovsdb_connection "tcp:127.0.0.1:6640"
crudini --set $cfg_ml2 ovn vif_type "ovs"


crudini --set $cfg_l3 DEFAULT l3_agent_manager "neutron.agent.l3_agent.L3NATAgentWithStateReport"
crudini --set $cfg_l3 DEFAULT external_network_bridge "br-ex"
crudini --set $cfg_l3 DEFAULT interface_driver "openvswitch"
crudini --set $cfg_l3 DEFAULT ovs_use_veth "False"
crudini --set $cfg_l3 AGENT root_helper_daemon "sudo /usr/bin/neutron-rootwrap-daemon /etc/neutron/rootwrap.conf"
crudini --set $cfg_l3 AGENT root_helper "sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf"


crudini --set $cfg_lbaas service_auth auth_version "2"
crudini --set $cfg_lbaas service_auth admin_password "password"
crudini --set $cfg_lbaas service_auth admin_user "admin"
crudini --set $cfg_lbaas service_auth admin_tenant_name "admin"
crudini --set $cfg_lbaas service_auth auth_url "http://${KEYSTONE_SERVICE_HOST}:5000/v2.0"
crudini --set $cfg_lbaas service_providers service_provider "LOADBALANCERV2:Haproxy:neutron_lbaas.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default"


crudini --set $cfg_lbaas_haproxy DEFAULT interface_driver "openvswitch"
crudini --set $cfg_lbaas_haproxy DEFAULT ovs_use_veth "False"
crudini --set $cfg_lbaas_haproxy haproxy loadbalancer_state_path "/var/lib/${OS_COMP}/state/lbaas"
crudini --set $cfg_lbaas_haproxy haproxy user_group "haproxy"

exec neutron-l3-agent --config-file $cfg --config-file $cfg_l3 --debug
