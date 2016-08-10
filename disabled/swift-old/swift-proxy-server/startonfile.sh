#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SWIFT RINGS"
################################################################################
mkdir -p /etc/os-swift
mkdir -p /etc/swift-devices
for SWIFT_RING_CONFIG in /etc/swift-devices/*; do
   SWIFT_RING=$(echo "$SWIFT_RING_CONFIG" | rev | cut -d"/" -f1 | rev)
   sed 's/\\n/\n/g' $SWIFT_RING_CONFIG > /etc/os-swift/$SWIFT_RING.env
   sed '/^\s*$/d' -i /etc/os-swift/$SWIFT_RING.env
   sed -e 's/^/export /' -i /etc/os-swift/$SWIFT_RING.env
   source /etc/os-swift/$SWIFT_RING.env
done


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






CMD="/usr/bin/swift-proxy-server"
ARGS="/etc/swift/proxy-server.conf --verbose"



#SWIFT_PROXY_BIND_IP=$(ip -f inet -o addr show $SWIFT_PROXY_BIND_DEV|cut -d\  -f 7 | cut -d/ -f 1)
SWIFT_PROXY_BIND_IP="0.0.0.0"

check_required_vars \
    SWIFT_ACCOUNT_SVC_RING_DEVICES \
    SWIFT_ACCOUNT_SVC_RING_HOSTS \
    SWIFT_ACCOUNT_SVC_RING_MIN_PART_HOURS \
    SWIFT_ACCOUNT_SVC_RING_NAME \
    SWIFT_ACCOUNT_SVC_RING_PART_POWER \
    SWIFT_ACCOUNT_SVC_RING_REPLICAS \
    SWIFT_ACCOUNT_SVC_RING_WEIGHTS \
    SWIFT_ACCOUNT_SVC_RING_ZONES \
    SWIFT_CONTAINER_SVC_RING_DEVICES \
    SWIFT_CONTAINER_SVC_RING_HOSTS \
    SWIFT_CONTAINER_SVC_RING_MIN_PART_HOURS \
    SWIFT_CONTAINER_SVC_RING_NAME \
    SWIFT_CONTAINER_SVC_RING_PART_POWER \
    SWIFT_CONTAINER_SVC_RING_REPLICAS \
    SWIFT_CONTAINER_SVC_RING_WEIGHTS \
    SWIFT_CONTAINER_SVC_RING_ZONES \
    SWIFT_KEYSTONE_PASSWORD \
    SWIFT_KEYSTONE_USER \
    SWIFT_OBJECT_SVC_RING_DEVICES \
    SWIFT_OBJECT_SVC_RING_HOSTS \
    SWIFT_OBJECT_SVC_RING_MIN_PART_HOURS \
    SWIFT_OBJECT_SVC_RING_NAME \
    SWIFT_OBJECT_SVC_RING_PART_POWER \
    SWIFT_OBJECT_SVC_RING_REPLICAS \
    SWIFT_OBJECT_SVC_RING_WEIGHTS \
    SWIFT_OBJECT_SVC_RING_ZONES \
    SWIFT_PROXY_ACCOUNT_AUTOCREATE \
    SWIFT_PROXY_AUTH_PLUGIN \
    SWIFT_PROXY_BIND_IP \
    SWIFT_PROXY_BIND_PORT \
    SWIFT_PROXY_DELAY_AUTH_DECISION \
    SWIFT_PROXY_DIR \
    SWIFT_PROXY_OPERATOR_ROLES \
    SWIFT_PROXY_SIGNING_DIR \
    SWIFT_USER


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


crudini --set $cfg DEFAULT bind_port "${SWIFT_PROXY_BIND_PORT}"
crudini --set $cfg DEFAULT user "${SWIFT_USER}"
crudini --set $cfg DEFAULT swift_dir "${SWIFT_PROXY_DIR}"
crudini --set $cfg DEFAULT bind_ip "${SWIFT_PROXY_BIND_IP}"

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

# Swift has no concept of the S3's resource owner; the resources
# (i.e. containers and objects) created via the Swift API have no owner
# information. This option specifies how the swift3 middleware handles them
# with the S3 API.  If this option is 'false', such kinds of resources will be
# invisible and no users can access them with the S3 API.  If set to 'true',
# the resource without owner is belong to everyone and everyone can access it
# with the S3 API.  If you care about S3 compatibility, set 'false' here.  This
# option makes sense only when the s3_acl option is set to 'true' and your
# Swift cluster has the resources created via the Swift API.
crudini --set $cfg DEFAULT allow_no_owner "false"

# Set a region name of your Swift cluster.  Note that Swift3 doesn't choose a
# region of the newly created bucket actually.  This value is used only for the
# GET Bucket location API.
crudini --set $cfg DEFAULT location "UK"

# Set the default maximum number of objects returned in the GET Bucket
# response.
crudini --set $cfg DEFAULT max_bucket_listing "1000"

# Set the maximum number of objects we can delete with the Multi-Object Delete
# operation.
crudini --set $cfg DEFAULT max_multi_delete_objects "1000"

# If set to 'true', Swift3 uses its own metadata for ACL
# (e.g. X-Container-Sysmeta-Swift3-Acl) to achieve the best S3 compatibility.
# If set to 'false', Swift3 tries to use Swift ACL (e.g. X-Container-Read)
# instead of S3 ACL as far as possible.  If you want to keep backward
# compatibility with Swift3 1.7 or earlier, set false here
# If set to 'false' after set to 'true' and put some container/object,
# all users will be able to access container/object.
# Note that s3_acl doesn't keep the acl consistency between S3 API and Swift
# API. (e.g. when set s3acl to true and PUT acl, we won't get the acl
# information via Swift API at all and the acl won't be applied against to
# Swift API even if it is for a bucket currently supported.)
# Note that s3_acl currently supports only keystone and tempauth.
# DON'T USE THIS for production before enough testing for your use cases.
# This stuff is still under development and it might cause something
# you don't expect.
crudini --set $cfg DEFAULT s3_acl "false"

# Specify a host name of your Swift cluster.  This enables virtual-hosted style
# requests.
crudini --set $cfg DEFAULT storage_domain "swift-api.canny.io"



crudini --set $cfg filter:container_sync use "egg:swift#container_sync"

crudini --set $cfg filter:bulk use "egg:swift#bulk"

crudini --set $cfg filter:ratelimit use "egg:swift#ratelimit"





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



################################################################################
echo "${OS_DISTRO}: Swift: Building Ring: Object (${SWIFT_OBJECT_SVC_RING_NAME}) "
################################################################################

python /opt/harbor/build-swift-ring.py \
    -f ${SWIFT_OBJECT_SVC_RING_NAME} \
    -p ${SWIFT_OBJECT_SVC_RING_PART_POWER} \
    -r ${SWIFT_OBJECT_SVC_RING_REPLICAS} \
    -m ${SWIFT_OBJECT_SVC_RING_MIN_PART_HOURS} \
    -H ${SWIFT_OBJECT_SVC_RING_HOSTS} \
    -w ${SWIFT_OBJECT_SVC_RING_WEIGHTS} \
    -d ${SWIFT_OBJECT_SVC_RING_DEVICES} \
    -z ${SWIFT_OBJECT_SVC_RING_ZONES}


################################################################################
echo "${OS_DISTRO}: Swift: Building Ring: Account (${SWIFT_ACCOUNT_SVC_RING_NAME}) "
################################################################################

python /opt/harbor/build-swift-ring.py \
    -f ${SWIFT_ACCOUNT_SVC_RING_NAME} \
    -p ${SWIFT_ACCOUNT_SVC_RING_PART_POWER} \
    -r ${SWIFT_ACCOUNT_SVC_RING_REPLICAS} \
    -m ${SWIFT_ACCOUNT_SVC_RING_MIN_PART_HOURS} \
    -H ${SWIFT_ACCOUNT_SVC_RING_HOSTS} \
    -w ${SWIFT_ACCOUNT_SVC_RING_WEIGHTS} \
    -d ${SWIFT_ACCOUNT_SVC_RING_DEVICES} \
    -z ${SWIFT_ACCOUNT_SVC_RING_ZONES}


################################################################################
echo "${OS_DISTRO}: Swift: Building Ring: Container (${SWIFT_CONTAINER_SVC_RING_NAME}) "
################################################################################

python /opt/harbor/build-swift-ring.py \
    -f ${SWIFT_CONTAINER_SVC_RING_NAME} \
    -p ${SWIFT_CONTAINER_SVC_RING_PART_POWER} \
    -r ${SWIFT_CONTAINER_SVC_RING_REPLICAS} \
    -m ${SWIFT_CONTAINER_SVC_RING_MIN_PART_HOURS} \
    -H ${SWIFT_CONTAINER_SVC_RING_HOSTS} \
    -w ${SWIFT_CONTAINER_SVC_RING_WEIGHTS} \
    -d ${SWIFT_CONTAINER_SVC_RING_DEVICES} \
    -z ${SWIFT_CONTAINER_SVC_RING_ZONES}


################################################################################
echo "${OS_DISTRO}: Swift: Launching ($CMD $ARGS) "
################################################################################
exec $CMD $ARGS
