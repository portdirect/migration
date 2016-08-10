#!/bin/bash
set -e

tail -f /dev/null
(
source /etc/os-container.env


mkdir -p /srv/node/account
mkdir -p /srv/node/container
mkdir -p /srv/node/object
chown -R swift:swift /srv/node
mkdir -p /var/cache/swift
chown -R swift:swift /var/cache/swift
chown -R swift:swift /var/lock



curl --insecure -o /etc/swift/proxy-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/proxy-server.conf-sample?h=stable/liberty
cfg=/etc/swift/proxy-server.conf
crudini --set $cfg DEFAULT bind_port "8088"
crudini --set $cfg DEFAULT user "swift"
crudini --set $cfg DEFAULT swift_dir "/etc/swift"

crudini --set $cfg pipeline:main pipeline "catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server"
crudini --set $cfg app:proxy-server use "egg:swift#proxy"
crudini --set $cfg app:proxy-server account_autocreate "true"

crudini --set $cfg filter:keystoneauth use "egg:swift#keystoneauth"
crudini --set $cfg filter:keystoneauth operator_roles "admin,user"



crudini --set $cfg filter:keystoneauth paste.filter_factory "keystonemiddleware.auth_token:filter_factory"

crudini --set $cfg filter:keystoneauth auth_uri https://keystone.port.direct:5000
crudini --set $cfg filter:keystoneauth auth_url https://keystone.port.direct:35357
crudini --set $cfg filter:keystoneauth auth_plugin "password"
crudini --set $cfg filter:keystoneauth project_domain_id "default"
crudini --set $cfg filter:keystoneauth user_domain_id "default"
crudini --set $cfg filter:keystoneauth project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:keystoneauth username "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:keystoneauth password "${SWIFT_KEYSTONE_PASSWORD}"
crudini --set $cfg filter:keystoneauth delay_auth_decision "true"

for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg filter:authtoken $option
done

crudini --set $cfg filter:authtoken paste.filter_factory "keystonemiddleware.auth_token:filter_factory"
crudini --set $cfg filter:authtoken auth_plugin "password"
crudini --set $cfg filter:authtoken auth_url "https://keystone.port.direct:35357/"
crudini --set $cfg filter:authtoken user_domain_name "Default"
crudini --set $cfg filter:authtoken project_domain_name "Default"
crudini --set $cfg filter:authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:authtoken username "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:authtoken password "${SWIFT_KEYSTONE_PASSWORD}"
crudini --set $cfg filter:authtoken auth_version "v3"
crudini --set $cfg filter:authtoken delay_auth_decision "true"




crudini --set $cfg filter:cache use "egg:swift#memcache"
crudini --set $cfg filter:cache memcache_servers "127.0.0.1:11211"








crudini --set $cfg pipeline:main pipeline "catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server"

crudini --set $cfg pipeline:main pipeline "catch_errors gatekeeper healthcheck proxy-logging cache swift3 s3token container_sync bulk ratelimit authtoken keystoneauth staticweb container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server"




crudini --set $cfg filter:swift3 use "egg:swift3#swift3"
crudini --set $cfg filter:swift3 location "${OS_DOMAIN}"

crudini --set $cfg filter:s3token paste.filter_factory "keystonemiddleware.s3_token:filter_factory"
crudini --set $cfg filter:s3token auth_port "35357"
crudini --set $cfg filter:s3token auth_host "${KEYSTONE_ADMIN_SERVICE_HOST}"
crudini --set $cfg filter:s3token auth_protocol "${KEYSTONE_AUTH_PROTOCOL}"
crudini --set $cfg filter:s3token admin_user "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:s3token admin_tenant_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:s3token admin_password "${SWIFT_KEYSTONE_PASSWORD}"


crudini --set $cfg filter:staticweb use "egg:swift#staticweb"

crudini --set $cfg DEFAULT allow_no_owner "false"
crudini --set $cfg DEFAULT location "${OS_DOMAIN}"
crudini --set $cfg DEFAULT max_bucket_listing "1000"
crudini --set $cfg DEFAULT max_multi_delete_objects "1000"
crudini --set $cfg DEFAULT s3_acl "false"
crudini --set $cfg DEFAULT storage_domain "swift.${OS_DOMAIN}"






MANAGEMENT_INTERFACE_IP_ADDRESS=$(ip -f inet -o addr show br2 |cut -d\  -f 7 | cut -d/ -f 1)
MANAGEMENT_INTERFACE_IP_ADDRESS=127.0.0.1

curl --insecure -o /etc/swift/account-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/account-server.conf-sample?h=stable/liberty
cfg=/etc/swift/account-server.conf
crudini --set $cfg DEFAULT bind_ip "${MANAGEMENT_INTERFACE_IP_ADDRESS}"
crudini --set $cfg DEFAULT bind_port "6002"
crudini --set $cfg DEFAULT user "swift"
crudini --set $cfg DEFAULT swift_dir "/etc/swift"
crudini --set $cfg DEFAULT devices "/tmp/node"
crudini --set $cfg DEFAULT mount_check "False"

crudini --set $cfg pipeline:main pipeline "healthcheck recon account-server"
crudini --set $cfg filter:recon use "egg:swift#recon"
crudini --set $cfg filter:recon recon_cache_path "/var/cache/swift"

crudini --set $cfg DEFAULT  eventlet_debug "True"

curl --insecure -o /etc/swift/container-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/container-server.conf-sample?h=stable/liberty
cfg=/etc/swift/container-server.conf
crudini --set $cfg DEFAULT bind_ip "${MANAGEMENT_INTERFACE_IP_ADDRESS}"
crudini --set $cfg DEFAULT bind_port "6001"
crudini --set $cfg DEFAULT user "swift"
crudini --set $cfg DEFAULT swift_dir "/etc/swift"
crudini --set $cfg DEFAULT devices "/srv/node"
crudini --set $cfg DEFAULT mount_check "False"
crudini --set $cfg pipeline:main pipeline "healthcheck recon container-server"
crudini --set $cfg filter:recon use "egg:swift#recon"
crudini --set $cfg filter:recon recon_cache_path "/var/cache/swift"



curl --insecure -o /etc/swift/object-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/object-server.conf-sample?h=stable/liberty
cfg=/etc/swift/object-server.conf
crudini --set $cfg DEFAULT bind_ip "${MANAGEMENT_INTERFACE_IP_ADDRESS}"
crudini --set $cfg DEFAULT bind_port "6000"
crudini --set $cfg DEFAULT user "swift"
crudini --set $cfg DEFAULT swift_dir "/etc/swift"
crudini --set $cfg DEFAULT devices "/srv/node"
crudini --set $cfg DEFAULT mount_check "False"
crudini --set $cfg DEFAULT max_clients "1024"
crudini --set $cfg DEFAULT workers "1"
crudini --set $cfg DEFAULT disable_fallocate "true"
crudini --set $cfg pipeline:main pipeline "healthcheck recon object-server"
crudini --set $cfg filter:recon use "egg:swift#recon"
crudini --set $cfg filter:recon recon_cache_path "/var/cache/swift"
crudini --set $cfg filter:recon recon_lock_path  "/var/lock"
crudini --set $cfg app:object-server use "egg:swiftonfile#object"
crudini --set $cfg app:object-server log_facility "LOG_LOCAL2"
crudini --set $cfg app:object-server log_facility "DEBUG"
crudini --set $cfg app:object-server log_facility "on"
crudini --set $cfg app:object-server disk_chunk_size "65536"
crudini --set $cfg DEFAULT  eventlet_debug "True"








# curl -o /etc/swift/object-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/object-server.conf-sample?h=stable/liberty


























cd /etc/swift

swift-ring-builder account.builder create 1 1 1
swift-ring-builder account.builder add --region 1 --zone 1 --ip ${MANAGEMENT_INTERFACE_IP_ADDRESS} --port 6002 --device account --weight 100
swift-ring-builder account.builder
swift-ring-builder account.builder rebalance


swift-ring-builder container.builder create 2 1 1
swift-ring-builder container.builder add --region 1 --zone 1 --ip ${MANAGEMENT_INTERFACE_IP_ADDRESS} --port 6001 --device container --weight 100
swift-ring-builder container.builder
swift-ring-builder container.builder rebalance

swift-ring-builder object.builder create 1 1 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip ${MANAGEMENT_INTERFACE_IP_ADDRESS} --port 6000 --device object --weight 100
swift-ring-builder object.builder
swift-ring-builder object.builder rebalance























curl --insecure -o /etc/swift/swift.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/swift.conf-sample?h=stable/liberty
cfg=/etc/swift/swift.conf
crudini --set $cfg swift-hash swift_hash_path_suffix "HASH_PATH_SUFFIX"
crudini --set $cfg swift-hash swift_hash_path_prefix "HASH_PATH_PREFIX"


crudini --set $cfg  storage-policy:0 name "swiftonfile"
crudini --set $cfg  storage-policy:0 default "yes"

chown -R root:swift /etc/swift
























################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSL"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt


cfg=/etc/swift/proxy-server.conf
crudini --set $cfg DEFAULT cert_file /etc/pki/tls/certs/ca.crt
crudini --set $cfg DEFAULT key_file /etc/pki/tls/private/ca.key


################################################################################
echo "${OS_DISTRO}: Swift: Launching ($CMD $ARGS) "
################################################################################
/usr/bin/swift-proxy-server /etc/swift/proxy-server.conf --verbose


/usr/bin/swift-account-auditor /etc/swift/account-server.conf --verbose &
/usr/bin/swift-account-reaper /etc/swift/account-server.conf --verbose &
/usr/bin/swift-account-replicator /etc/swift/account-server.conf --verbose &
/usr/bin/swift-account-server /etc/swift/account-server.conf --verbose



/usr/bin/swift-container-auditor /etc/swift/container-server.conf --verbose &
/usr/bin/swift-container-replicator /etc/swift/container-server.conf --verbose &
/usr/bin/swift-container-updater /etc/swift/container-server.conf --verbose &
/usr/bin/swift-container-server /etc/swift/container-server.conf --verbose



/usr/bin/swift-object-auditor /etc/swift/object-server.conf --verbose &
/usr/bin/swift-object-replicator /etc/swift/object-server.conf --verbose &
/usr/bin/swift-object-updater /etc/swift/object-server.conf --verbose &
/usr/bin/swift-object-server /etc/swift/object-server.conf --verbose






cfg=/etc/swift/object-server.conf



cfg=/etc/swift/swift.conf














if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi




cfg=/etc/swift/proxy-server.conf

# Logging
crudini --set $cfg \
        DEFAULT \
        verbose \
        true
crudini --set $cfg \
        DEFAULT \
        debug \
        true
crudini --set $cfg DEFAULT use_stderr true
mkdir -p /var/log/swift
chown -R swift:swift /var/log/swift

cfg=/etc/swift/object-server.conf
crudini --set $cfg DEFAULT devices "/etc/os-swift"
crudini --set $cfg DEFAULT mount_check "false"
crudini --set $cfg DEFAULT bind_port "6050"
crudini --set $cfg DEFAULT max_clients "1024"
crudini --set $cfg DEFAULT workers "1"
crudini --set $cfg DEFAULT disable_fallocate "true"
crudini --set $cfg pipeline:main pipeline "object-server"
crudini --set $cfg app:object-server use "egg:swiftonfile#object"
crudini --set $cfg app:object-server log_facility "LOG_LOCAL2"
crudini --set $cfg app:object-server log_facility "DEBUG"
crudini --set $cfg app:object-server log_facility "on"
crudini --set $cfg app:object-server disk_chunk_size "65536"





cfg=/etc/swift/swift.conf
crudini --set $cfg storage-policy:0 name "swiftonfile"
crudini --set $cfg storage-policy:0 default "yes"
crudini --set $cfg storage-policy:0 policy_type "replication"




cd /etc/swift
swift-ring-builder container.builder create 1 1 1
swift-ring-builder container.builder add r1z1-127.0.0.1:6001/container 1
swift-ring-builder container.builder rebalance
swift-ring-builder account.builder create 1 1 1
swift-ring-builder account.builder add r1z1-127.0.0.1:6002/account 1
swift-ring-builder account.builder rebalance
swift-ring-builder object.builder create 1 1 1
swift-ring-builder object.builder add r1z1-127.0.0.1:6000/object 1
swift-ring-builder object.builder rebalance





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/config-swift.sh



: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${ADMIN_USER:="admin"}
: ${ADMIN_USER_DOMAIN:="default"}
: ${ADMIN_USER_PROJECT_DOMAIN:="default"}
: ${DEFAULT_REGION:="HarborOS"}
: ${SWIFT_PROXY_PIPELINE_MAIN:="catch_errors gatekeeper healthcheck cache container_sync bulk ratelimit authtoken keystoneauth slo dlo proxy-server"}


: ${SWIFT_USER:="swift"}









#SWIFT_PROXY_BIND_IP=$(ip -f inet -o addr show $SWIFT_PROXY_BIND_DEV|cut -d\  -f 7 | cut -d/ -f 1)
SWIFT_PROXY_BIND_IP="0.0.0.0"



################################################################################
echo "${OS_DISTRO}: Swift: Configuration "
################################################################################


cfg=/etc/swift/proxy-server.conf

# Logging
crudini --set $cfg \
        DEFAULT \
        verbose \
        true
crudini --set $cfg \
        DEFAULT \
        debug \
        true
crudini --set $cfg DEFAULT use_stderr true
mkdir -p /var/log/swift
chown -R swift:swift /var/log/swift


crudini --set $cfg DEFAULT bind_port "8088"
crudini --set $cfg DEFAULT user "${SWIFT_USER}"
crudini --set $cfg DEFAULT swift_dir "${SWIFT_PROXY_DIR}"
crudini --set $cfg DEFAULT bind_ip "0.0.0.0"

crudini --set $cfg pipeline:main pipeline "catch_errors gatekeeper healthcheck cache swift3 s3token container_sync bulk ratelimit authtoken keystoneauth staticweb slo dlo proxy-server"

crudini --set $cfg app:proxy-server account_autocreate "${SWIFT_PROXY_ACCOUNT_AUTOCREATE}"

crudini --set $cfg filter:swift3 use egg:swift3#swift3
crudini --set $cfg filter:swift3 location ${DEFAULT_REGION}

crudini --del $cfg filter:keystone
crudini --set $cfg filter:keystoneauth use egg:swift#keystoneauth
crudini --set $cfg filter:keystoneauth operator_roles "${SWIFT_PROXY_OPERATOR_ROLES}"



#crudini --set $cfg filter:s3token auth_plugin "password"
#crudini --set $cfg filter:s3token auth_url "http://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
#crudini --set $cfg filter:s3token user_domain_name "Default"
#crudini --set $cfg filter:s3token project_domain_name "Default"
#crudini --set $cfg filter:s3token project_name "${SERVICE_TENANT_NAME}"
#crudini --set $cfg filter:s3token username "${SWIFT_KEYSTONE_USER}"
#crudini --set $cfg filter:s3token password "${SWIFT_KEYSTONE_PASSWORD}"

crudini --set $cfg filter:s3token paste.filter_factory "keystonemiddleware.s3_token:filter_factory"
crudini --set $cfg filter:s3token auth_port "35357"
crudini --set $cfg filter:s3token auth_host "${KEYSTONE_ADMIN_SERVICE_HOST}"
crudini --set $cfg filter:s3token auth_protocol "${KEYSTONE_AUTH_PROTOCOL}"
crudini --set $cfg filter:s3token admin_user "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:s3token admin_tenant_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:s3token admin_password "${SWIFT_KEYSTONE_PASSWORD}"


crudini --set $cfg filter:staticweb use "egg:swift#staticweb"
crudini --set $cfg DEFAULT allow_no_owner "false"
crudini --set $cfg DEFAULT location "UK"
crudini --set $cfg DEFAULT max_bucket_listing "1000"
crudini --set $cfg DEFAULT max_multi_delete_objects "1000"
crudini --set $cfg DEFAULT s3_acl "false"
crudini --set $cfg DEFAULT storage_domain "swift.${OS_DOMAIN}"



crudini --set $cfg filter:container_sync use "egg:swift#container_sync"

crudini --set $cfg filter:bulk use "egg:swift#bulk"

crudini --set $cfg filter:ratelimit use "egg:swift#ratelimit"



for option in auth_protocol auth_host auth_port identity_uri auth_uri admin_tenant_name admin_user admin_password; do
    crudini --del $cfg filter:authtoken $option
done


crudini --set $cfg filter:authtoken auth_plugin "password"
crudini --set $cfg filter:authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/"
crudini --set $cfg filter:authtoken user_domain_name "Default"
crudini --set $cfg filter:authtoken project_domain_name "Default"
crudini --set $cfg filter:authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:authtoken username "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:authtoken password "${SWIFT_KEYSTONE_PASSWORD}"
crudini --set $cfg filter:authtoken auth_version "v3"
crudini --set $cfg filter:authtoken delay_auth_decision "${SWIFT_PROXY_DELAY_AUTH_DECISION}"
crudini --set $cfg filter:authtoken signing_dir "${SWIFT_PROXY_SIGNING_DIR}"


#crudini --set $cfg filter:cache memcache_servers "${OPENSTACK_COMPONENT}-memcached:11211"

crudini --set $cfg filter:gatekeeper use "egg:swift#gatekeeper"

crudini --set $cfg filter:slo use "egg:swift#slo"

crudini --set $cfg filter:dlo use "egg:swift#dlo"







# Create swift user and group if they don't exist
id -u swift &>/dev/null || useradd --user-group swift


# TODO(pbourke): should these go into the Dockerfile instead?
# TODO(pbourke): do we need a data vol for these?
mkdir -p ${SWIFT_PROXY_SIGNING_DIR}
chown swift: ${SWIFT_PROXY_SIGNING_DIR}
chmod 0700 ${SWIFT_PROXY_SIGNING_DIR}
