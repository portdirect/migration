#!/bin/sh
MARIADB_SERVICE_HOST=${MARIADB_SERVICE_HOST}
MEMCACHED_SERVICE_HOST=${MEMCACHED_SERVICE_HOST}
KEYSTONE_SERVICE_HOST=${KEYSTONE_SERVICE_HOST}
RABBITMQ_SERVICE_HOST=${RABBITMQ_SERVICE_HOST}
NEUTRON_SERVICE_HOST=${RABBITMQ_SERVICE_HOST}
NOVA_SERVICE_HOST=${NOVA_SERVICE_HOST}
GLANCE_SERVICE_HOST=${GLANCE_SERVICE_HOST}
OCTAVIA_SERVICE_HOST=${OCTAVIA_SERVICE_HOST}
OCTAVIA_HEALTH_SERVICE_HOST=${OCTAVIA_HEALTH_SERVICE_HOST}
OVS_NB_DB_IP=${OVS_NB_DB_IP}
OVS_SB_DB_IP=${OVS_SB_DB_IP}
DB_NAME=${OS_COMP}
DB_USER=${OS_COMP}
DB_PASSWORD=${DB_ROOT_PASSWORD}


export cfg=/etc/octavia/octavia.conf


crudini --set $cfg DEFAULT debug "True"
crudini --set $cfg DEFAULT use_syslog "False"
crudini --set $cfg DEFAULT logging_exception_prefix "%(color)s%(asctime)s.%(msecs)03d TRACE %(name)s %(instance)s"
crudini --set $cfg DEFAULT logging_debug_format_suffix "from (pid=%(process)d) %(funcName)s %(pathname)s:%(lineno)d"
crudini --set $cfg DEFAULT logging_default_format_string "%(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [-%(color)s] %(instance)s%(color)s%(message)s"
crudini --set $cfg DEFAULT logging_context_format_string "%(asctime)s.%(msecs)03d %(color)s%(levelname)s %(name)s [%(request_id)s %(user_name)s %(project_id)s%(color)s] %(instance)s%(color)s%(message)s"


crudini --set $cfg DEFAULT transport_url "rabbit://guest:guest@${RABBITMQ_SERVICE_HOST}:5672/"
crudini --set $cfg DEFAULT api_handler "queue_producer"


crudini --set $cfg database connection "mysql+pymysql://${DB_USER}:${DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DB_NAME}?charset=utf8"


crudini --set $cfg health_manager bind_port "5555"
crudini --set $cfg health_manager bind_ip "${OCTAVIA_HEALTH_SERVICE_HOST}"
crudini --set $cfg health_manager controller_ip_port_list "${OCTAVIA_HEALTH_SERVICE_HOST}:5555"
crudini --set $cfg health_manager heartbeat_key "insecure"



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
crudini --set $cfg keystone_authtoken_v3 admin_user_domain "default"
crudini --set $cfg keystone_authtoken_v3 admin_project_domain "default"



crudini --set $cfg certificates ca_private_key_passphrase "foobar"
crudini --set $cfg certificates ca_private_key "/etc/octavia/certs/private/cakey.pem"
crudini --set $cfg certificates ca_certificate "/etc/octavia/certs/ca_01.pem"



crudini --set $cfg haproxy_amphora server_ca "/etc/octavia/certs/ca_01.pem"
crudini --set $cfg haproxy_amphora client_cert "/etc/octavia/certs/client.pem"
crudini --set $cfg haproxy_amphora key_path "/etc/octavia/.ssh/octavia_ssh_key"
crudini --set $cfg haproxy_amphora base_path "/var/lib/octavia"
crudini --set $cfg haproxy_amphora base_cert_dir "/var/lib/octavia/certs"
# Absolute path to a custom HAProxy template file
# haproxy_template =
crudini --set $cfg haproxy_amphora connection_max_retries "1500"
crudini --set $cfg haproxy_amphora connection_retry_interval "1"





crudini --set $cfg controller_worker amp_boot_network_list "25350505-f498-4b57-a841-43904b436340"
crudini --set $cfg controller_worker amp_image_tag "amphora"
crudini --set $cfg controller_worker amp_secgroup_list "6bea25aa-d90d-48f1-8f75-19dda28bc0a4"
crudini --set $cfg controller_worker amp_ssh_key_name "octavia_ssh_key"
crudini --set $cfg controller_worker amp_active_wait_sec "1"
crudini --set $cfg controller_worker amp_active_retries "100"
crudini --set $cfg controller_worker network_driver "allowed_address_pairs_driver"
crudini --set $cfg controller_worker compute_driver "compute_nova_driver"
crudini --set $cfg controller_worker amphora_driver "amphora_haproxy_rest_driver"
crudini --set $cfg controller_worker amp_flavor_id "10"


crudini --set $cfg oslo_messaging topic "octavia_prov"
crudini --set $cfg oslo_messaging rpc_thread_pool_size "2"


crudini --set $cfg house_keeping load_balancer_expiry_age "3600"
crudini --set $cfg house_keeping amphora_expiry_age "3600"
