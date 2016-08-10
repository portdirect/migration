#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=proxy-config
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars OS_DOMAIN


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RUNNING"
################################################################################
crudini --set $cfg DEFAULT bind_port "8088"
crudini --set $cfg DEFAULT user "swift"
crudini --set $cfg DEFAULT swift_dir "/etc/swift"


crudini --set $cfg pipeline:main pipeline "catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server"


crudini --set $cfg app:proxy-server use "egg:swift#proxy"
crudini --set $cfg app:proxy-server account_autocreate "True"

crudini --set $cfg filter:keystoneauth use "egg:swift#keystoneauth"
crudini --set $cfg filter:keystoneauth operator_roles "admin,user"

crudini --set $cfg filter:authtoken paste.filter_factory "keystonemiddleware.auth_token:filter_factory"


crudini --set $cfg filter:authtoken auth_uri "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}"
crudini --set $cfg filter:authtoken auth_url "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357"
crudini --set $cfg filter:authtoken memcached_servers "127.0.0.1:11211"

crudini --set $cfg filter:authtoken auth_type "password"
crudini --set $cfg filter:authtoken project_domain_name "default"
crudini --set $cfg filter:authtoken user_domain_name "default"
crudini --set $cfg filter:authtoken project_name "${SERVICE_TENANT_NAME}"
crudini --set $cfg filter:authtoken username "${SWIFT_KEYSTONE_USER}"
crudini --set $cfg filter:authtoken password "${SWIFT_KEYSTONE_PASSWORD}"
crudini --set $cfg filter:authtoken delay_auth_decision "true"





crudini --set $cfg filter:cache use "egg:swift#memcache"
crudini --set $cfg filter:cache memcache_servers "127.0.0.1:11211"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSL"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt
crudini --set $cfg DEFAULT cert_file /etc/pki/tls/certs/ca.crt
crudini --set $cfg DEFAULT key_file /etc/pki/tls/private/ca.key
