#!/bin/sh
set -e
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


cfg=/etc/cinder/cinder.conf


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


crudini --set $cfg DEFAULT graceful_shutdown_timeout "5"
crudini --set $cfg DEFAULT os_privileged_user_tenant "service"
crudini --set $cfg DEFAULT os_privileged_user_password "password"
crudini --set $cfg DEFAULT os_privileged_user_name "nova"
crudini --set $cfg DEFAULT glance_api_servers "http://${GLANCE_SERVICE_HOST}:9292"
crudini --set $cfg DEFAULT osapi_volume_workers "2"
crudini --set $cfg DEFAULT logging_exception_prefix "%(color)s%(asctime)s.%(msecs)03d TRACE %(name)s ^[[01;35m%(instance)s^[[00m"
crudini --set $cfg DEFAULT logging_debug_format_suffix "^[[00;33mfrom (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d^[[00m"
crudini --set $cfg DEFAULT logging_default_format_string "%(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [^[[00;36m-%(color)s] ^[[01;35m%(instance)s%(color)s%(message)s^[[00m"
crudini --set $cfg DEFAULT logging_context_format_string "%(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [^[[01;36m%(request_id)s ^[[00;36m%(user_id)s %(project_id)s%(color)s] ^[[01;35m%(instance)s%(color)s%(message)s^[[00m"
crudini --set $cfg DEFAULT volume_clear "zero"
crudini --set $cfg DEFAULT transport_url "rabbit://guest:guest@${RABBITMQ_SERVICE_HOST}:5672/"
crudini --set $cfg DEFAULT default_volume_type "lvmdriver-1"
crudini --set $cfg DEFAULT enabled_backends "lvmdriver-1"
crudini --set $cfg DEFAULT os_region_name "RegionOne"
crudini --set $cfg DEFAULT my_ip "${EXPOSED_IP}"
crudini --set $cfg DEFAULT periodic_interval "60"
crudini --set $cfg DEFAULT state_path "/var/lib/cinder"
crudini --set $cfg DEFAULT osapi_volume_listen "0.0.0.0"
crudini --set $cfg DEFAULT osapi_volume_extension "cinder.api.contrib.standard_extensions"
crudini --set $cfg DEFAULT rootwrap_config "/etc/cinder/rootwrap.conf"
crudini --set $cfg DEFAULT api_paste_config "/etc/cinder/api-paste.ini"
crudini --set $cfg DEFAULT iscsi_helper "tgtadm"
crudini --set $cfg DEFAULT debug "True"
crudini --set $cfg DEFAULT auth_strategy "keystone"
crudini --set $cfg DEFAULT nova_catalog_admin_info "compute:nova:adminURL"
crudini --set $cfg DEFAULT nova_catalog_info "compute:nova:publicURL"

crudini --set $cfg database connection "mysql+pymysql://${DB_USER}_api:${DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DB_NAME}_api?charset=utf8"

crudini --set $cfg oslo_concurrency lock_path "/var/lib/cinder/lock"

crudini --set $cfg lvmdriver-1 lvm_type "default"
crudini --set $cfg lvmdriver-1 iscsi_helper "tgtadm"
crudini --set $cfg lvmdriver-1 volume_group "stack-volumes-lvmdriver-1"
crudini --set $cfg lvmdriver-1 volume_driver "cinder.volume.drivers.lvm.LVMVolumeDriver"
crudini --set $cfg lvmdriver-1 volume_backend_name "lvmdriver-1"


exec cinder-scheduler --config-file $cfg --debug
