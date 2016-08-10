#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
# DB Settings
: ${MARIADB_SERVICE_HOST:="${MARIADB_HOSTNAME}.$OS_DOMAIN"}
# Messaging Settings
: ${RABBITMQ_SERVICE_HOST:="${RABBITMQ_HOSTNAME}.$OS_DOMAIN"}
# Keystone Settings
: ${KEYSTONE_ADMIN_SERVICE_HOST:="${KEYSTONE_ADMIN_SERVICE_HOSTNAME}.$OS_DOMAIN"}
: ${KEYSTONE_PUBLIC_SERVICE_HOST:="${KEYSTONE_PUBLIC_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Murano Settings
: ${DESIGNATE_API_SERVICE_HOST:="${DESIGNATE_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}

: ${ADMIN_USER_DOMAIN:="default"}
: ${ADMIN_USER_PROJECT_DOMAIN:="default"}
: ${SERVICE_TENANT_NAME:="services"}
: ${DEFAULT_REGION:="HarborOS"}
: ${KEYSTONE_AUTH_PROTOCOL:="http"}



. /opt/harbor/harbor-common.sh

check_required_vars DESIGNATE_DB_PASSWORD DESIGNATE_KEYSTONE_PASSWORD \
                    KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_PUBLIC_SERVICE_PORT \
                    DESIGNATE_KEYSTONE_USER \
                    DESIGNATE_DB_USER DESIGNATE_DB_NAME KEYSTONE_AUTH_PROTOCOL \
                    KEYSTONE_PUBLIC_SERVICE_PORT RABBITMQ_SERVICE_HOST \
                    VERBOSE_LOGGING DEBUG_LOGGING

fail_unless_db
dump_vars


################################################################################
echo "${OS_DISTRO}: CONFIG: Generating Openrc"
################################################################################
cat > /openrc <<EOF
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v3"
export OS_USERNAME="${DESIGNATE_KEYSTONE_USER}"
export OS_PASSWORD="${DESIGNATE_KEYSTONE_PASSWORD}"
export OS_USER_DOMAIN="${ADMIN_USER_DOMAIN}"
export OS_PROJECT_NAME="${SERVICE_TENANT_NAME}"
export OS_PROJECT_DOMAIN="${ADMIN_USER_PROJECT_DOMAIN}"
EOF


cfg=/etc/designate/designate.conf
################################################################################
echo "${OS_DISTRO}: CONFIG: General"
################################################################################
##[DEFAULT]
# Where an option is commented out, but filled in this shows the default
# value of that option

########################
## General Configuration
########################
# Show more verbose log output (sets INFO log level output)
crudini --set $cfg DEFAULT verbose True

# Show debugging output in logs (sets DEBUG log level output)
crudini --set $cfg DEFAULT debug True

# Top-level directory for maintaining designate's state
# state_path = /var/lib/designate

# Log Configuration
#log_config = None

# Log directory
#logdir = /var/log/designate

# Driver used for issuing notifications
# notification_driver = messaging

# Notification Topics
#notification_topics = notifications

# Use "sudo designate-rootwrap /etc/designate/rootwrap.conf" to use the real
# root filter facility.
# Change to "sudo" to skip the filtering and just run the comand directly
#root_helper = sudo designate-rootwrap /etc/designate/rootwrap.conf

# Which networking API to use, Defaults to neutron
#network_api = neutron

# RabbitMQ Config
#rabbit_userid = guest
#rabbit_password = guest
#rabbit_virtual_host = /
#rabbit_use_ssl = False
#rabbit_hosts = 127.0.0.1:5672

########################
## Service Configuration
########################
#-----------------------
# Central Service
#-----------------------
##[service:central]
# Number of central worker processes to spawn
#workers = None

# Number of central greenthreads to spawn
#threads = 1000

# Maximum domain name length
#max_domain_name_len = 255

# Maximum recordset name length
#max_recordset_name_len = 255

# Minimum TTL
#min_ttl = None

# The name of the default pool
#default_pool_id = '794ccc2c-d751-44fe-b57f-8894c9f5c842'

## Managed resources settings

# Email to use for managed resources like domains created by the FloatingIP API
#managed_resource_email = hostmaster@example.com.

# Tenant ID to own all managed resources - like auto-created records etc.
#managed_resource_tenant_id = 123456

#-----------------------
# API Service
#-----------------------
##[service:api]
# Number of api worker processes to spawn
#workers = None

# Number of api greenthreads to spawn
#threads = 1000

# Enable host request headers
#enable_host_header = False

# The base uri used in responses
#api_base_uri = 'http://127.0.0.1:9001/'

# Address to bind the API server
#api_host = 0.0.0.0

# Port the bind the API server to
#api_port = 9001

# Maximum line size of message headers to be accepted. max_header_line may
# need to be increased when using large tokens (typically those generated by
# the Keystone v3 API with big service catalogs).
#max_header_line = 16384

# Authentication strategy to use - can be either "noauth" or "keystone"
#auth_strategy = keystone

# Enable Version 1 API (deprecated)
#enable_api_v1 = True

# Enabled API Version 1 extensions
# Can be one or more of : diagnostics, quotas, reports, sync, touch
#enabled_extensions_v1 =

# Enable Version 2 API
#enable_api_v2 = True

# Enabled API Version 2 extensions
#enabled_extensions_v2 =

# Default per-page limit for the V2 API, a value of None means show all results
# by default
#default_limit_v2 = 20

# Max page size in the V2 API
#max_limit_v2 = 1000

# Enable Admin API (experimental)
#enable_api_admin = False

# Enabled Admin API extensions
# Can be one or more of : reports, quotas, counts, tenants, zones
# zone export is in zones extension
#enabled_extensions_admin =

# Default per-page limit for the Admin API, a value of None means show all results
# by default
#default_limit_admin = 20

# Max page size in the Admin API
#max_limit_admin = 1000

# Show the pecan HTML based debug interface (v2 only)
# This is only useful for development, and WILL break python-designateclient
# if an error occurs
#pecan_debug = False

#-----------------------
# Keystone Middleware
#-----------------------
##[keystone_authtoken]
#auth_host = 127.0.0.1
#auth_port = 35357
#auth_protocol = http
#admin_tenant_name = service
#admin_user = designate
#admin_password = designate

#-----------------------
# Sink Service
#-----------------------
##[service:sink]
# List of notification handlers to enable, configuration of these needs to
# correspond to a [handler:my_driver] section below or else in the config
# Can be one or more of : nova_fixed, neutron_floatingip
#enabled_notification_handlers =

#-----------------------
# mDNS Service
#-----------------------
##[service:mdns]
# Number of mdns worker processes to spawn
#workers = None

# Number of mdns greenthreads to spawn
#threads = 1000

# mDNS Bind Host
#host = 0.0.0.0

# mDNS Port Number
#port = 5354

# mDNS TCP Backlog
#tcp_backlog = 100

# mDNS TCP Receive Timeout
#tcp_recv_timeout = 0.5

# Enforce all incoming queries (including AXFR) are TSIG signed
#query_enforce_tsig = False

# Send all traffic over TCP
#all_tcp = False

# Maximum message size to emit
#max_message_size = 65535

#-----------------------
# Agent Service
#-----------------------
##[service:agent]
#workers = None
#host = 0.0.0.0
#port = 5358
#tcp_backlog = 100
#allow_notify = 127.0.0.1
#masters = 127.0.0.1:5354
#backend_driver = fake
#transfer_source = None
#notify_delay = 0

#-----------------------
# Zone Manager Service
#-----------------------
##[service:zone_manager]
# Number of Zone Manager worker processes to spawn
#workers = None

# Number of Zone Manager greenthreads to spawn
#threads = 1000

# List of Zone Manager tasks to enable, a value of None will enable all tasks.
# Can be one or more of: periodic_exists
#enabled_tasks = None

# Whether to allow synchronous zone exports
#export_synchronous = True

#------------------------
# Deleted domains purging
#------------------------
##[zone_manager_task:domain_purge]
# How frequently to purge deleted domains, in seconds
#interval = 3600  # 1h

# How many records to be deleted on each run
#batch_size = 100

# How old deleted records should be (deleted_at) to be purged, in seconds
#time_threshold = 604800  # 7 days

#-----------------------
# Pool Manager Service
#-----------------------
##[service:pool_manager]
# Number of Pool Manager worker processes to spawn
#workers = None

# Number of Pool Manager greenthreads to spawn
#threads = 1000

# The ID of the pool managed by this instance of the Pool Manager
#pool_id = 794ccc2c-d751-44fe-b57f-8894c9f5c842

# The percentage of servers requiring a successful update for a domain change
# to be considered active
#threshold_percentage = 100

# The time to wait for a response from a server
#poll_timeout = 30

# The time between retrying to send a request and waiting for a response from a
# server
#poll_retry_interval = 15

# The maximum number of times to retry sending a request and wait for a
# response from a server
#poll_max_retries = 10

# The time to wait before sending the first request to a server
#poll_delay = 5

# Enable the recovery thread
#enable_recovery_timer = True

# The time between recovering from failures
#periodic_recovery_interval = 120

# Enable the sync thread
#enable_sync_timer = True

# The time between synchronizing the servers with storage
#periodic_sync_interval = 1800

# Zones Updated within last N seconds will be syncd. Use None to sync all zones
#periodic_sync_seconds = None

# The cache driver to use
#cache_driver = memcache

###################################
## Pool Manager Cache Configuration
###################################
#-----------------------
# SQLAlchemy Pool Manager Cache
#-----------------------
##[pool_manager_cache:sqlalchemy]
#connection = sqlite:///$state_path/designate_pool_manager.sqlite
#connection_debug = 100
#connection_trace = False
#sqlite_synchronous = True
#idle_timeout = 3600
#max_retries = 10
#retry_interval = 10

#-----------------------
# Memcache Pool Manager Cache
#-----------------------
##[pool_manager_cache:memcache]
#memcached_servers = None
#expiration = 3600

#####################
## Pool Configuration
#####################

# This section does not have the defaults filled in but demonstrates an
# example pool / server set up. Different backends will have different options.

#[pool:794ccc2c-d751-44fe-b57f-8894c9f5c842]
#nameservers = 0f66b842-96c2-4189-93fc-1dc95a08b012
#targets = f26e0b32-736f-4f0a-831b-039a415c481e
#also_notifies = 192.0.2.1:53, 192.0.2.2:53

#[pool_nameserver:0f66b842-96c2-4189-93fc-1dc95a08b012]
#port = 53
#host = 192.168.27.100

#[pool_target:f26e0b32-736f-4f0a-831b-039a415c481e]
#options = rndc_host: 192.168.27.100, rndc_port: 953, rndc_config_file: /etc/bind/rndc.conf, rndc_key_file: /etc/bind/rndc.key, port: 53, host: 192.168.27.100
#masters = 192.168.27.100:5354
#type = bind9


##############
## Network API
##############
##[network_api:neutron]
# Comma separated list of values, formatted "<name>|<neutron_uri>"
#endpoints = RegionOne|http://localhost:9696
#endpoint_type = publicURL
#timeout = 30
#admin_username = designate
#admin_password = designate
#admin_tenant_name = designate
#auth_url = http://localhost:35357/v2.0
#insecure = False
#auth_strategy = keystone
#ca_certificates_file =

########################
## Storage Configuration
########################
#-----------------------
# SQLAlchemy Storage
#-----------------------
##[storage:sqlalchemy]
# Database connection string - to configure options for a given implementation
# like sqlalchemy or other see below
#connection = sqlite:///$state_path/designate.sqlite
#connection_debug = 0
#connection_trace = False
#sqlite_synchronous = True
#idle_timeout = 3600
#max_retries = 10
#retry_interval = 10

########################
## Handler Configuration
########################
#-----------------------
# Nova Fixed Handler
#-----------------------
##[handler:nova_fixed]
# Domain ID of domain to create records in. Should be pre-created
#domain_id =
#notification_topics = notifications
#control_exchange = 'nova'
#format = '%(octet0)s-%(octet1)s-%(octet2)s-%(octet3)s.%(domain)s'
#format = '%(hostname)s.%(domain)s'

#------------------------
# Neutron Floating Handler
#------------------------
##[handler:neutron_floatingip]
# Domain ID of domain to create records in. Should be pre-created
#domain_id =
#notification_topics = notifications
#control_exchange = 'neutron'
#format = '%(octet0)s-%(octet1)s-%(octet2)s-%(octet3)s.%(domain)s'
#format = '%(hostname)s.%(domain)s'

#############################
## Agent Backend Configuration
#############################
##[backend:agent:bind9]
#rndc_host = 127.0.0.1
#rndc_port = 953
#rndc_config_file = /etc/rndc.conf
#rndc_key_file = /etc/rndc.key
#zone_file_path = $state_path/zones
#query_destination = 127.0.0.1
#
##[backend:agent:denominator]
#name = dynect
#config_file = /etc/denominator.conf

########################
## Library Configuration
########################
##[oslo_concurrency]
# Path for Oslo Concurrency to store lock files, defaults to the value
# of the state_path setting.
#lock_path = $state_path

########################
## Coordination
########################
##[coordination]
# URL for the coordination backend to use.
#backend_url = kazoo://127.0.0.1/

########################
## Hook Points
########################
# Hook Points are enabled when added to the config and there has been
# a package that provides the corresponding named designate.hook_point
# entry point.

# [hook_point:name_of_hook_point]
# some_param_for_hook = 42
# Hooks can be disabled in the config
# enabled = False

# Hook can also be applied to the import path when the hook has not
# been given an explicit name. The name is created from the hook
# target function / method:
#
#   name = '%s.%s' % (func.__module__, func.__name__)

# [hook_point:designate.api.v2.controllers.zones.get_one]
