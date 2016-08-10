#!/bin/sh
set -e
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


export cfg=/etc/swift/object-server.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RUNNING"
################################################################################
/opt/harbor/swift/swift-common.sh
/opt/harbor/swift/config-object.sh
/opt/harbor/swift/build-ring-account.sh
/opt/harbor/swift/build-ring-container.sh
/opt/harbor/swift/build-ring-object.sh
