#!/bin/bash
OPENSTACK_COMPONENT="senlin"

: ${SENLIN_DB_USER:=senlin}
: ${SENLIN_DB_NAME:=senlin}
: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${SENLIN_KEYSTONE_USER:=senlin}
: ${ADMIN_USER:="admin"}
: ${ADMIN_USER_DOMAIN:="default"}
: ${ADMIN_USER_PROJECT_DOMAIN:="default"}
: ${DEFAULT_REGION:="HarborOS"}



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Config"
################################################################################
cfg="/etc/senlin/senlin.conf"


#################################################################################################################
# [DEFAULT]

#
# From oslo.log
#

# Print debugging output (set logging level to DEBUG instead of default INFO level). (boolean value)
crudini --set $cfg DEFAULT debug true

# If set to false, will disable INFO logging level, making WARNING the default. (boolean value)
# This option is deprecated for removal.
# Its value may be silently ignored in the future.
crudini --set $cfg DEFAULT verbose true

# The name of a logging configuration file. This file is appended to any existing logging configuration files. For
# details about logging configuration files, see the Python logging module documentation. Note that when logging
# configuration files are used then all logging configuration is set in the configuration file and other logging
# configuration options are ignored (for example, log_format). (string value)
# Deprecated group/name - [DEFAULT]/log_config
#log_config_append = <None>

# DEPRECATED. A logging.Formatter log message format string which may use any of the available logging.LogRecord
# attributes. This option is deprecated.  Please use logging_context_format_string and logging_default_format_string
# instead. This option is ignored if log_config_append is set. (string value)
#log_format = <None>

# Format string for %%(asctime)s in log records. Default: %(default)s . This option is ignored if log_config_append is
# set. (string value)
#log_date_format = %Y-%m-%d %H:%M:%S

# (Optional) Name of log file to output to. If no default is set, logging will go to stdout. This option is ignored if
# log_config_append is set. (string value)
# Deprecated group/name - [DEFAULT]/logfile
#log_file = <None>

# (Optional) The base directory used for relative --log-file paths. This option is ignored if log_config_append is set.
# (string value)
# Deprecated group/name - [DEFAULT]/logdir
#log_dir = <None>

# (Optional) Uses logging handler designed to watch file system. When log file is moved or removed this handler will
# open a new log file with specified path instantaneously. It makes sense only if log-file option is specified and
# Linux platform is used. This option is ignored if log_config_append is set. (boolean value)
#watch_log_file = false

# Use syslog for logging. Existing syslog format is DEPRECATED and will be changed later to honor RFC5424. This option
# is ignored if log_config_append is set. (boolean value)
#use_syslog = false

# (Optional) Enables or disables syslog rfc5424 format for logging. If enabled, prefixes the MSG part of the syslog
# message with APP-NAME (RFC5424). The format without the APP-NAME is deprecated in Kilo, and will be removed in
# Mitaka, along with this option. This option is ignored if log_config_append is set. (boolean value)
# This option is deprecated for removal.
# Its value may be silently ignored in the future.
#use_syslog_rfc_format = true

# Syslog facility to receive log lines. This option is ignored if log_config_append is set. (string value)
#syslog_log_facility = LOG_USER

# Log output to standard error. This option is ignored if log_config_append is set. (boolean value)
#use_stderr = true

# Format string to use for log messages with context. (string value)
#logging_context_format_string = %(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s

# Format string to use for log messages without context. (string value)
#logging_default_format_string = %(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s

# Data to append to log format when level is DEBUG. (string value)
#logging_debug_format_suffix = %(funcName)s %(pathname)s:%(lineno)d

# Prefix each line of exception output with this format. (string value)
#logging_exception_prefix = %(asctime)s.%(msecs)03d %(process)d ERROR %(name)s %(instance)s

# List of logger=LEVEL pairs. This option is ignored if log_config_append is set. (list value)
#default_log_levels = amqp=WARN,amqplib=WARN,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,oslo.messaging=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,urllib3.connectionpool=WARN,websocket=WARN,requests.packages.urllib3.util.retry=WARN,urllib3.util.retry=WARN,keystonemiddleware=WARN,routes.middleware=WARN,stevedore=WARN,taskflow=WARN

# Enables or disables publication of error events. (boolean value)
#publish_errors = false

# The format for an instance that is passed with the log message. (string value)
#instance_format = "[instance: %(uuid)s] "

# The format for an instance UUID that is passed with the log message. (string value)
#instance_uuid_format = "[instance: %(uuid)s] "

# Enables or disables fatal status of deprecations. (boolean value)
#fatal_deprecations = false

#
# From oslo.messaging
#

# Size of RPC connection pool. (integer value)
# Deprecated group/name - [DEFAULT]/rpc_conn_pool_size
#rpc_conn_pool_size = 30

# ZeroMQ bind address. Should be a wildcard (*), an ethernet interface, or IP. The "host" option should point or
# resolve to this address. (string value)
#rpc_zmq_bind_address = *

# MatchMaker driver. (string value)
#rpc_zmq_matchmaker = local

# ZeroMQ receiver listening port. (integer value)
#rpc_zmq_port = 9501

# Number of ZeroMQ contexts, defaults to 1. (integer value)
#rpc_zmq_contexts = 1

# Maximum number of ingress messages to locally buffer per topic. Default is unlimited. (integer value)
#rpc_zmq_topic_backlog = <None>

# Directory for holding IPC sockets. (string value)
#rpc_zmq_ipc_dir = /var/run/openstack

# Name of this node. Must be a valid hostname, FQDN, or IP address. Must match "host" option, if running Nova. (string
# value)
#rpc_zmq_host = localhost

# Seconds to wait before a cast expires (TTL). Only supported by impl_zmq. (integer value)
#rpc_cast_timeout = 30

# Heartbeat frequency. (integer value)
#matchmaker_heartbeat_freq = 300

# Heartbeat time-to-live. (integer value)
#matchmaker_heartbeat_ttl = 600

# Size of executor thread pool. (integer value)
# Deprecated group/name - [DEFAULT]/rpc_thread_pool_size
#executor_thread_pool_size = 64

# The Drivers(s) to handle sending notifications. Possible values are messaging, messagingv2, routing, log, test, noop
# (multi valued)
#notification_driver =

# AMQP topic used for OpenStack notifications. (list value)
# Deprecated group/name - [rpc_notifier2]/topics
#notification_topics = notifications

# Seconds to wait for a response from a call. (integer value)
#rpc_response_timeout = 60

# A URL representing the messaging driver to use and its full configuration. If not set, we fall back to the
# rpc_backend option and driver specific configuration. (string value)
#transport_url = <None>

# The messaging driver to use, defaults to rabbit. Other drivers include qpid and zmq. (string value)
crudini --set $cfg DEFAULT rpc_backend rabbit

# The default exchange under which topics are scoped. May be overridden by an exchange name specified in the
# transport_url option. (string value)
#control_exchange = openstack

#
# From oslo.service.periodic_task
#

# Some periodic tasks can be run in a separate process. Should we run them here? (boolean value)
#run_external_periodic_tasks = true

#
# From oslo.service.service
#

# Enable eventlet backdoor.  Acceptable values are 0, <port>, and <start>:<end>, where 0 results in listening on a
# random tcp port number; <port> results in listening on the specified port number (and not enabling backdoor if that
# port is in use); and <start>:<end> results in listening on the smallest unused port number within the specified range
# of port numbers.  The chosen port is displayed in the service's log file. (string value)
#backdoor_port = <None>

# Enables or disables logging values of all registered options when starting a service (at DEBUG level). (boolean
# value)
#log_options = true

# Specify a timeout after which a gracefully shutdown server will exit. Zero value means endless wait. (integer value)
#graceful_shutdown_timeout = 0

#
# From senlin.common.config
#

# Default cloud backend to use. (string value)
#cloud_backend = openstack

#
# From senlin.common.config
#

# Name of the engine node. This can be an opaque identifier. It is not necessarily a hostname, FQDN, or IP address.
# (string value)
#host = senlin-api.canny.io

#
# From senlin.common.config
#

# The directory to search for environment files. (string value)
#environment_dir = /etc/senlin/environments

# Maximum nodes allowed per top-level cluster. (integer value)
#max_nodes_per_cluster = 1000

# Maximum number of clusters any one project may have active at one time. (integer value)
#max_clusters_per_project = 100

# Maximum events per cluster. Older events will be deleted when this is reached.  Set to 0 for unlimited events per
# cluster. (integer value)
#max_events_per_cluster = 3000

# Timeout in seconds for actions. (integer value)
#default_action_timeout = 3600

# Maximum number of actions per batch when operating a cluster. (integer value)
#max_actions_per_batch = 10

# Default priority for policies attached to a cluster. (integer value)
#default_policy_priority = 50

# Number of times trying to grab a lock. (integer value)
#lock_retry_times = 3

# Number of seconds between lock retries. (integer value)
#lock_retry_interval = 10

# Error wait time in seconds for cluster action (ie. create or update). (integer value)
#error_wait_time = 240

# RPC timeout for the engine liveness check that is used for cluster locking. (integer value)
#engine_life_check_timeout = 2

# Flag to indicate whether to enforce unique names for Senlin objects belonging to the same project. (boolean value)
#name_unique = false

#
# From senlin.common.config
#

# Seconds between running periodic tasks. (integer value)
#periodic_interval = 60

# Default region name used to get services endpoints. (string value)
#region_name_for_services = <None>

# Maximum raw byte size of data from web response. (integer value)
#max_response_size = 524288

# Maximum depth allowed when using nested clusters. (integer value)
#max_nested_cluster_depth = 3

# Number of senlin-engine processes to fork and run. (integer value)
#num_engine_workers = 1

#
# From senlin.common.wsgi
#

# Maximum raw byte size of JSON request body. Should be larger than max_template_size. (integer value)
#max_json_body_size = 1048576


#################################################################################################################
# [authentication]

#
# From senlin.common.config
#

# Complete public identity V3 API endpoint. (string value)
crudini --set $cfg authentication auth_url "http://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v3"

# Senlin service user name (string value)
crudini --set $cfg authentication service_username "${SENLIN_KEYSTONE_USER}"

# Password specified for the Senlin service user. (string value)
crudini --set $cfg authentication service_password "${SENLIN_KEYSTONE_PASSWORD}"

# Name of the service project. (string value)
crudini --set $cfg authentication service_project_name "${SERVICE_TENANT_NAME}"

# Name of the domain for the service user. (string value)
crudini --set $cfg authentication service_user_domain "Default"

# Name of the domain for the service project. (string value)
crudini --set $cfg authentication service_project_domain "Default"


#################################################################################################################
# [database]

#
# From oslo.db
#

# The file name to use with SQLite. (string value)
# Deprecated group/name - [DEFAULT]/sqlite_db
#sqlite_db = oslo.sqlite

# If True, SQLite uses synchronous mode. (boolean value)
# Deprecated group/name - [DEFAULT]/sqlite_synchronous
#sqlite_synchronous = true

# The back end to use for the database. (string value)
# Deprecated group/name - [DEFAULT]/db_backend
#backend = sqlalchemy

# The SQLAlchemy connection string to use to connect to the database. (string value)
# Deprecated group/name - [DEFAULT]/sql_connection
# Deprecated group/name - [DATABASE]/sql_connection
# Deprecated group/name - [sql]/connection
crudini --set $cfg database connection "mysql://${SENLIN_DB_USER}:${SENLIN_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${SENLIN_DB_NAME}"

# The SQLAlchemy connection string to use to connect to the slave database. (string value)
#slave_connection = <None>

# The SQL mode to be used for MySQL sessions. This option, including the default, overrides any server-set SQL mode. To
# use whatever SQL mode is set by the server configuration, set this to no value. Example: mysql_sql_mode= (string
# value)
#mysql_sql_mode = TRADITIONAL

# Timeout before idle SQL connections are reaped. (integer value)
# Deprecated group/name - [DEFAULT]/sql_idle_timeout
# Deprecated group/name - [DATABASE]/sql_idle_timeout
# Deprecated group/name - [sql]/idle_timeout
#idle_timeout = 3600

# Minimum number of SQL connections to keep open in a pool. (integer value)
# Deprecated group/name - [DEFAULT]/sql_min_pool_size
# Deprecated group/name - [DATABASE]/sql_min_pool_size
#min_pool_size = 1

# Maximum number of SQL connections to keep open in a pool. (integer value)
# Deprecated group/name - [DEFAULT]/sql_max_pool_size
# Deprecated group/name - [DATABASE]/sql_max_pool_size
crudini --set $cfg database max_pool_size 1000

# Maximum number of database connection retries during startup. Set to -1 to specify an infinite retry count. (integer
# value)
# Deprecated group/name - [DEFAULT]/sql_max_retries
# Deprecated group/name - [DATABASE]/sql_max_retries
#max_retries = 10

# Interval between retries of opening a SQL connection. (integer value)
# Deprecated group/name - [DEFAULT]/sql_retry_interval
# Deprecated group/name - [DATABASE]/reconnect_interval
#retry_interval = 10

# If set, use this value for max_overflow with SQLAlchemy. (integer value)
# Deprecated group/name - [DEFAULT]/sql_max_overflow
# Deprecated group/name - [DATABASE]/sqlalchemy_max_overflow
crudini --set $cfg database max_overflow -1

# Verbosity of SQL debugging information: 0=None, 100=Everything. (integer value)
# Deprecated group/name - [DEFAULT]/sql_connection_debug
#connection_debug = 0

# Add Python stack traces to SQL as comment strings. (boolean value)
# Deprecated group/name - [DEFAULT]/sql_connection_trace
#connection_trace = false

# If set, use this value for pool_timeout with SQLAlchemy. (integer value)
# Deprecated group/name - [DATABASE]/sqlalchemy_pool_timeout
#pool_timeout = <None>

# Enable the experimental use of database reconnect on connection lost. (boolean value)
#use_db_reconnect = false

# Seconds between retries of a database transaction. (integer value)
#db_retry_interval = 1

# If True, increases the interval between retries of a database operation up to db_max_retry_interval. (boolean value)
#db_inc_retry_interval = true

# If db_inc_retry_interval is set, the maximum seconds between retries of a database operation. (integer value)
#db_max_retry_interval = 10

# Maximum retries in case of connection error or deadlock error before error is raised. Set to -1 to specify an
# infinite retry count. (integer value)
#db_max_retries = 20


#################################################################################################################
# [eventlet_opts]

#
# From senlin.common.wsgi
#

# If false, closes the client socket explicitly. (boolean value)
#wsgi_keep_alive = true

# Timeout for client connections' socket operations. If an incoming connection is idle for this number of seconds it
# will be closed. A value of '0' indicates waiting forever. (integer value)
#client_socket_timeout = 900


#################################################################################################################
# [keystone_authtoken]

#
# From keystonemiddleware.auth_token
#
crudini --set $cfg keystone_authtoken auth_plugin "password"
crudini --set $cfg keystone_authtoken auth_url "http://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg keystone_authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg keystone_authtoken user_domain_name "Default"
crudini --set $cfg keystone_authtoken project_domain_name "Default"
crudini --set $cfg keystone_authtoken username "${SENLIN_KEYSTONE_USER}"
crudini --set $cfg keystone_authtoken password "${SENLIN_KEYSTONE_PASSWORD}"

# Complete public Identity API endpoint. (string value)
#auth_uri = <None>

# API version of the admin Identity API endpoint. (string value)
crudini --set $cfg keystone_authtoken auth_version "v${KEYSTONE_API_VERSION}"

# Do not handle authorization requests within the middleware, but delegate the authorization decision to downstream
# WSGI components. (boolean value)
#delay_auth_decision = false

# Request timeout value for communicating with Identity API server. (integer value)
#http_connect_timeout = <None>

# How many times are we trying to reconnect when communicating with Identity API Server. (integer value)
#http_request_max_retries = 3

# Env key for the swift cache. (string value)
#cache = <None>

# Required if identity server requires client certificate (string value)
#certfile = <None>

# Required if identity server requires client certificate (string value)
#keyfile = <None>

# A PEM encoded Certificate Authority to use when verifying HTTPs connections. Defaults to system CAs. (string value)
#cafile = <None>

# Verify HTTPS connections. (boolean value)
#insecure = false

# The region in which the identity server can be found. (string value)
#region_name = <None>

# Directory used to cache files related to PKI tokens. (string value)
#signing_dir = <None>

# Optionally specify a list of memcached server(s) to use for caching. If left undefined, tokens will instead be cached
# in-process. (list value)
# Deprecated group/name - [DEFAULT]/memcache_servers
#memcached_servers = <None>

# In order to prevent excessive effort spent validating tokens, the middleware caches previously-seen tokens for a
# configurable duration (in seconds). Set to -1 to disable caching completely. (integer value)
#token_cache_time = 300

# Determines the frequency at which the list of revoked tokens is retrieved from the Identity service (in seconds). A
# high number of revocation events combined with a low cache duration may significantly reduce performance. (integer
# value)
#revocation_cache_time = 10

# (Optional) If defined, indicate whether token data should be authenticated or authenticated and encrypted. Acceptable
# values are MAC or ENCRYPT.  If MAC, token data is authenticated (with HMAC) in the cache. If ENCRYPT, token data is
# encrypted and authenticated in the cache. If the value is not one of these options or empty, auth_token will raise an
# exception on initialization. (string value)
#memcache_security_strategy = <None>

# (Optional, mandatory if memcache_security_strategy is defined) This string is used for key derivation. (string value)
#memcache_secret_key = <None>

# (Optional) Number of seconds memcached server is considered dead before it is tried again. (integer value)
#memcache_pool_dead_retry = 300

# (Optional) Maximum total number of open connections to every memcached server. (integer value)
#memcache_pool_maxsize = 10

# (Optional) Socket timeout in seconds for communicating with a memcached server. (integer value)
#memcache_pool_socket_timeout = 3

# (Optional) Number of seconds a connection to memcached is held unused in the pool before it is closed. (integer
# value)
#memcache_pool_unused_timeout = 60

# (Optional) Number of seconds that an operation will wait to get a memcached client connection from the pool. (integer
# value)
#memcache_pool_conn_get_timeout = 10

# (Optional) Use the advanced (eventlet safe) memcached client pool. The advanced pool will only work under python 2.x.
# (boolean value)
#memcache_use_advanced_pool = false

# (Optional) Indicate whether to set the X-Service-Catalog header. If False, middleware will not ask for service
# catalog on token validation and will not set the X-Service-Catalog header. (boolean value)
#include_service_catalog = true

# Used to control the use and type of token binding. Can be set to: "disabled" to not check token binding. "permissive"
# (default) to validate binding information if the bind type is of a form known to the server and ignore it if not.
# "strict" like "permissive" but if the bind type is unknown the token will be rejected. "required" any form of token
# binding is needed to be allowed. Finally the name of a binding method that must be present in tokens. (string value)
#enforce_token_bind = permissive

# If true, the revocation list will be checked for cached tokens. This requires that PKI tokens are configured on the
# identity server. (boolean value)
#check_revocations_for_cached = false

# Hash algorithms to use for hashing PKI tokens. This may be a single algorithm or multiple. The algorithms are those
# supported by Python standard hashlib.new(). The hashes will be tried in the order given, so put the preferred one
# first for performance. The result of the first hash will be stored in the cache. This will typically be set to
# multiple values only while migrating from a less secure algorithm to a more secure one. Once all the old tokens are
# expired this option should be set to a single value for better performance. (list value)
#hash_algorithms = md5

# Prefix to prepend at the beginning of the path. Deprecated, use identity_uri. (string value)
#auth_admin_prefix =

# Host providing the admin Identity API endpoint. Deprecated, use identity_uri. (string value)
#auth_host = 127.0.0.1

# Port of the admin Identity API endpoint. Deprecated, use identity_uri. (integer value)
#auth_port = 35357

# Protocol of the admin Identity API endpoint (http or https). Deprecated, use identity_uri. (string value)
#auth_protocol = https

# Complete admin Identity API endpoint. This should specify the unversioned root endpoint e.g. https://localhost:35357/
# (string value)
#identity_uri = <None>

# This option is deprecated and may be removed in a future release. Single shared secret with the Keystone
# configuration used for bootstrapping a Keystone installation, or otherwise bypassing the normal authentication
# process. This option should not be used, use `admin_user` and `admin_password` instead. (string value)
#admin_token = <None>

# Service username. (string value)
#admin_user = <None>

# Service user password. (string value)
#admin_password = <None>

# Service tenant name. (string value)
#admin_tenant_name = admin


#################################################################################################################
# [matchmaker_redis]

#
# From oslo.messaging
#

# Host to locate redis. (string value)
#host = 127.0.0.1

# Use this port to connect to redis host. (integer value)
#port = 6379

# Password for Redis server (optional). (string value)
#password = <None>


#################################################################################################################
# [matchmaker_ring]

#
# From oslo.messaging
#

# Matchmaker ring file (JSON). (string value)
# Deprecated group/name - [DEFAULT]/matchmaker_ringfile
#ringfile = /etc/oslo/matchmaker_ring.json


#################################################################################################################
# [oslo_messaging_amqp]

#
# From oslo.messaging
#

# address prefix used when sending to a specific server (string value)
# Deprecated group/name - [amqp1]/server_request_prefix
#server_request_prefix = exclusive

# address prefix used when broadcasting to all servers (string value)
# Deprecated group/name - [amqp1]/broadcast_prefix
#broadcast_prefix = broadcast

# address prefix when sending to any server in group (string value)
# Deprecated group/name - [amqp1]/group_request_prefix
#group_request_prefix = unicast

# Name for the AMQP container (string value)
# Deprecated group/name - [amqp1]/container_name
#container_name = <None>

# Timeout for inactive connections (in seconds) (integer value)
# Deprecated group/name - [amqp1]/idle_timeout
#idle_timeout = 0

# Debug: dump AMQP frames to stdout (boolean value)
# Deprecated group/name - [amqp1]/trace
#trace = false

# CA certificate PEM file to verify server certificate (string value)
# Deprecated group/name - [amqp1]/ssl_ca_file
#ssl_ca_file =

# Identifying certificate PEM file to present to clients (string value)
# Deprecated group/name - [amqp1]/ssl_cert_file
#ssl_cert_file =

# Private key PEM file used to sign cert_file certificate (string value)
# Deprecated group/name - [amqp1]/ssl_key_file
#ssl_key_file =

# Password for decrypting ssl_key_file (if encrypted) (string value)
# Deprecated group/name - [amqp1]/ssl_key_password
#ssl_key_password = <None>

# Accept clients using either SSL or plain TCP (boolean value)
# Deprecated group/name - [amqp1]/allow_insecure_clients
#allow_insecure_clients = false


#################################################################################################################
# [oslo_messaging_qpid]

#
# From oslo.messaging
#

# Use durable queues in AMQP. (boolean value)
# Deprecated group/name - [DEFAULT]/amqp_durable_queues
# Deprecated group/name - [DEFAULT]/rabbit_durable_queues
#amqp_durable_queues = false

# Auto-delete queues in AMQP. (boolean value)
# Deprecated group/name - [DEFAULT]/amqp_auto_delete
#amqp_auto_delete = false

# Send a single AMQP reply to call message. The current behaviour since oslo-incubator is to send two AMQP replies -
# first one with the payload, a second one to ensure the other have finish to send the payload. We are going to remove
# it in the N release, but we must keep backward compatible at the same time. This option provides such compatibility -
# it defaults to False in Liberty and can be turned on for early adopters with a new installations or for testing.
# Please note, that this option will be removed in the Mitaka release. (boolean value)
#send_single_reply = false

# Qpid broker hostname. (string value)
# Deprecated group/name - [DEFAULT]/qpid_hostname
#qpid_hostname = localhost

# Qpid broker port. (integer value)
# Deprecated group/name - [DEFAULT]/qpid_port
#qpid_port = 5672

# Qpid HA cluster host:port pairs. (list value)
# Deprecated group/name - [DEFAULT]/qpid_hosts
#qpid_hosts = $qpid_hostname:$qpid_port

# Username for Qpid connection. (string value)
# Deprecated group/name - [DEFAULT]/qpid_username
#qpid_username =

# Password for Qpid connection. (string value)
# Deprecated group/name - [DEFAULT]/qpid_password
#qpid_password =

# Space separated list of SASL mechanisms to use for auth. (string value)
# Deprecated group/name - [DEFAULT]/qpid_sasl_mechanisms
#qpid_sasl_mechanisms =

# Seconds between connection keepalive heartbeats. (integer value)
# Deprecated group/name - [DEFAULT]/qpid_heartbeat
#qpid_heartbeat = 60

# Transport to use, either 'tcp' or 'ssl'. (string value)
# Deprecated group/name - [DEFAULT]/qpid_protocol
#qpid_protocol = tcp

# Whether to disable the Nagle algorithm. (boolean value)
# Deprecated group/name - [DEFAULT]/qpid_tcp_nodelay
#qpid_tcp_nodelay = true

# The number of prefetched messages held by receiver. (integer value)
# Deprecated group/name - [DEFAULT]/qpid_receiver_capacity
#qpid_receiver_capacity = 1

# The qpid topology version to use.  Version 1 is what was originally used by impl_qpid.  Version 2 includes some
# backwards-incompatible changes that allow broker federation to work.  Users should update to version 2 when they are
# able to take everything down, as it requires a clean break. (integer value)
# Deprecated group/name - [DEFAULT]/qpid_topology_version
#qpid_topology_version = 1


#################################################################################################################
# [oslo_messaging_rabbit]

#
# From oslo.messaging
#

# Use durable queues in AMQP. (boolean value)
# Deprecated group/name - [DEFAULT]/amqp_durable_queues
# Deprecated group/name - [DEFAULT]/rabbit_durable_queues
#amqp_durable_queues = false

# Auto-delete queues in AMQP. (boolean value)
# Deprecated group/name - [DEFAULT]/amqp_auto_delete
#amqp_auto_delete = false

# Send a single AMQP reply to call message. The current behaviour since oslo-incubator is to send two AMQP replies -
# first one with the payload, a second one to ensure the other have finish to send the payload. We are going to remove
# it in the N release, but we must keep backward compatible at the same time. This option provides such compatibility -
# it defaults to False in Liberty and can be turned on for early adopters with a new installations or for testing.
# Please note, that this option will be removed in the Mitaka release. (boolean value)
#send_single_reply = false

# SSL version to use (valid only if SSL enabled). Valid values are TLSv1 and SSLv23. SSLv2, SSLv3, TLSv1_1, and TLSv1_2
# may be available on some distributions. (string value)
# Deprecated group/name - [DEFAULT]/kombu_ssl_version
#kombu_ssl_version =

# SSL key file (valid only if SSL enabled). (string value)
# Deprecated group/name - [DEFAULT]/kombu_ssl_keyfile
#kombu_ssl_keyfile =

# SSL cert file (valid only if SSL enabled). (string value)
# Deprecated group/name - [DEFAULT]/kombu_ssl_certfile
#kombu_ssl_certfile =

# SSL certification authority file (valid only if SSL enabled). (string value)
# Deprecated group/name - [DEFAULT]/kombu_ssl_ca_certs
#kombu_ssl_ca_certs =

# How long to wait before reconnecting in response to an AMQP consumer cancel notification. (floating point value)
# Deprecated group/name - [DEFAULT]/kombu_reconnect_delay
#kombu_reconnect_delay = 1.0

# How long to wait before considering a reconnect attempt to have failed. This value should not be longer than
# rpc_response_timeout. (integer value)
#kombu_reconnect_timeout = 60

# The RabbitMQ broker address where a single node is used. (string value)
# Deprecated group/name - [DEFAULT]/rabbit_host
crudini --set $cfg oslo_messaging_rabbit rabbit_host "${RABBITMQ_SERVICE_HOST}"

# The RabbitMQ broker port where a single node is used. (integer value)
# Deprecated group/name - [DEFAULT]/rabbit_port
crudini --set $cfg oslo_messaging_rabbit rabbit_port 5672

# RabbitMQ HA cluster host:port pairs. (list value)
# Deprecated group/name - [DEFAULT]/rabbit_hosts
crudini --set $cfg oslo_messaging_rabbit rabbit_hosts "${RABBITMQ_SERVICE_HOST}:5672"

# Connect over SSL for RabbitMQ. (boolean value)
# Deprecated group/name - [DEFAULT]/rabbit_use_ssl
crudini --set $cfg oslo_messaging_rabbit rabbit_use_ssl "False"

# The RabbitMQ userid. (string value)
# Deprecated group/name - [DEFAULT]/rabbit_userid
crudini --set $cfg oslo_messaging_rabbit rabbit_userid "${RABBITMQ_USERID}"

# The RabbitMQ password. (string value)
# Deprecated group/name - [DEFAULT]/rabbit_password
crudini --set $cfg oslo_messaging_rabbit rabbit_password "${RABBITMQ_PASS}"

# The RabbitMQ login method. (string value)
# Deprecated group/name - [DEFAULT]/rabbit_login_method
#rabbit_login_method = AMQPLAIN

# The RabbitMQ virtual host. (string value)
# Deprecated group/name - [DEFAULT]/rabbit_virtual_host
crudini --set $cfg oslo_messaging_rabbit rabbit_virtual_host "/"

# How frequently to retry connecting with RabbitMQ. (integer value)
#rabbit_retry_interval = 1

# How long to backoff for between retries when connecting to RabbitMQ. (integer value)
# Deprecated group/name - [DEFAULT]/rabbit_retry_backoff
#rabbit_retry_backoff = 2

# Maximum number of RabbitMQ connection retries. Default is 0 (infinite retry count). (integer value)
# Deprecated group/name - [DEFAULT]/rabbit_max_retries
#rabbit_max_retries = 0

# Use HA queues in RabbitMQ (x-ha-policy: all). If you change this option, you must wipe the RabbitMQ database.
# (boolean value)
# Deprecated group/name - [DEFAULT]/rabbit_ha_queues
crudini --set $cfg oslo_messaging_rabbit rabbit_ha_queues "False"

# Number of seconds after which the Rabbit broker is considered down if heartbeat's keep-alive fails (0 disable the
# heartbeat). EXPERIMENTAL (integer value)
#heartbeat_timeout_threshold = 60

# How often times during the heartbeat_timeout_threshold we check the heartbeat. (integer value)
#heartbeat_rate = 2

# Deprecated, use rpc_backend=kombu+memory or rpc_backend=fake (boolean value)
# Deprecated group/name - [DEFAULT]/fake_rabbit
#fake_rabbit = false


#################################################################################################################
# [oslo_policy]

#
# From oslo.policy
#

# The JSON file that defines policies. (string value)
# Deprecated group/name - [DEFAULT]/policy_file
#policy_file = policy.json

# Default rule. Enforced when a requested rule is not found. (string value)
# Deprecated group/name - [DEFAULT]/policy_default_rule
#policy_default_rule = default

# Directories where policy configuration files are stored. They can be relative to any directory in the search path
# defined by the config_dir option, or absolute paths. The file defined by policy_file must exist for these directories
# to be searched.  Missing or empty directories are ignored. (multi valued)
# Deprecated group/name - [DEFAULT]/policy_dirs
# This option is deprecated for removal.
# Its value may be silently ignored in the future.
#policy_dirs = policy.d


#################################################################################################################
# [paste_deploy]

#
# From senlin.common.config
#

# The API paste config file to use. (string value)
#api_paste_config = api-paste.ini


#################################################################################################################
# [revision]

#
# From senlin.common.config
#

# Senlin API revision. (string value)
#senlin_api_revision = 1.0

# Senlin engine revision. (string value)
#senlin_engine_revision = 1.0


#################################################################################################################
# [senlin_api]

#
# From senlin.common.wsgi
#

# Address to bind the server. Useful when selecting a particular network interface. (ip address value)
crudini --set $cfg senlin_api bind_host 0.0.0.0

# The port on which the server will listen. (port value)
# Minimum value: 1
# Maximum value: 65535
crudini --set $cfg senlin_api bind_port ${SENLIN_API_SERVICE_PORT}

# Number of backlog requests to configure the socket with. (integer value)
#backlog = 4096

# Location of the SSL certificate file to use for SSL mode. (string value)
#cert_file = <None>

# Location of the SSL key file to use for enabling SSL mode. (string value)
#key_file = <None>

# Number of workers for Senlin service. (integer value)
#workers = 0

# Maximum line size of message headers to be accepted. max_header_line may need to be increased when using large tokens
# (typically those generated by the Keystone v3 API with big service catalogs). (integer value)
#max_header_line = 16384

# The value for the socket option TCP_KEEPIDLE.  This is the time in seconds that the connection must be idle before
# TCP starts sending keepalive probes. (integer value)
#tcp_keepidle = 600


#################################################################################################################
# [ssl]

#
# From oslo.service.sslutils
#

# CA certificate file to use to verify connecting clients. (string value)
# Deprecated group/name - [DEFAULT]/ssl_ca_file
#ca_file = <None>

# Certificate file to use when starting the server securely. (string value)
# Deprecated group/name - [DEFAULT]/ssl_cert_file
#cert_file = <None>

# Private key file to use when starting the server securely. (string value)
# Deprecated group/name - [DEFAULT]/ssl_key_file
#key_file = <None>
