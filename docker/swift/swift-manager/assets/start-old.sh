#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi
tail -f /dev/null
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


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars ETCDCTL_ENDPOINT



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_os_service_running keystone



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Magaging Service"
################################################################################


################################################################################
echo "${OS_DISTRO}: Defining Keystone Service Endoints"
################################################################################
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"









#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring Storage Rings"
################################################################################
/bin/config-rings.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up endpoints"
################################################################################
/bin/ipa-endpoint-manager.sh



#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Management Complete"
################################################################################
