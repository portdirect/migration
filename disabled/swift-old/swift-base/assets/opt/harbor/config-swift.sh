#!/bin/bash
set -e
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

: ${SWIFT_DEVICE:="br0"}
: ${SWIFT_MANAGEMENT_INTERFACE:="${SWIFT_DEVICE}"}
: ${SWIFT_ACCOUNT_SVC_BIND_DEV:="${SWIFT_DEVICE}"}
: ${SWIFT_ACCOUNT_SVC_BIND_PORT:="6002"}
: ${SWIFT_ACCOUNT_SVC_DEVICES:="/srv/node"}
: ${SWIFT_ACCOUNT_SVC_MOUNT_CHECK:="false"}
: ${SWIFT_CONTAINER_SVC_BIND_DEV:="${SWIFT_DEVICE}"}
: ${SWIFT_CONTAINER_SVC_BIND_PORT:="6001"}
: ${SWIFT_CONTAINER_SVC_DEVICES:="/srv/node"}
: ${SWIFT_CONTAINER_SVC_MOUNT_CHECK:="false"}
: ${SWIFT_DIR:="/etc/swift"}
: ${SWIFT_OBJECT_SVC_BIND_DEV:="${SWIFT_DEVICE}"}
: ${SWIFT_OBJECT_SVC_BIND_PORT:="6000"}
: ${SWIFT_OBJECT_SVC_DEVICES:="/srv/node"}
: ${SWIFT_OBJECT_SVC_MOUNT_CHECK:="false"}
: ${SWIFT_OBJECT_SVC_PIPELINE:="object-server"}
: ${SWIFT_PROXY_ACCOUNT_AUTOCREATE:="true"}
: ${SWIFT_PROXY_AUTH_PLUGIN:="password"}
: ${SWIFT_PROXY_BIND_DEV:="br0"}
: ${SWIFT_PROXY_BIND_PORT:="8088"}
: ${SWIFT_PROXY_DELAY_AUTH_DECISION:="true"}
: ${SWIFT_PROXY_DIR:="/etc/swift"}
: ${SWIFT_PROXY_OPERATOR_ROLES:="admin,_member_,user"}
: ${SWIFT_PROXY_SIGNING_DIR:="/var/cache/swift"}
: ${SWIFT_CONTAINER_SVC_RING_NAME:="/etc/swift/container.builder"}
: ${SWIFT_ACCOUNT_SVC_RING_NAME:="/etc/swift/account.builder"}
: ${SWIFT_OBJECT_SVC_RING_NAME:="/etc/swift/object.builder"}
: ${SWIFT_USER:="swift"}



check_required_vars SWIFT_HASH_PATH_SUFFIX

################################################################################
echo "${OS_DISTRO}: Swift: Base Configuration"
################################################################################

cfg=/etc/swift/swift.conf

crudini --set $cfg swift-hash swift_hash_path_suffix "${SWIFT_HASH_PATH_SUFFIX}"
