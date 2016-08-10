#!/bin/bash
set -e
source /etc/os-container.env
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
SWIFT_COMPONENT=${OPENSTACK_SUBCOMPONENT}
if [ "${SWIFT_COMPONENT}" = "proxy" ]
then
  SWIFT_SUBCOMPONENT="server"
else
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
  ################################################################################
  check_required_vars SWIFT_DEVICE ETCDCTL_ENDPOINT
  if [ "${SWIFT_SUBCOMPONENT}" = "server" ]
  then
    SWIFT_IP=$(ip -f inet -o addr show $SWIFT_DEVICE|cut -d\  -f 7 | cut -d/ -f 1)
    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating dns so that $(hostname -s).${OPENSTACK_SUBCOMPONENT}.storage.node.local points to ${SWIFT_IP}"
    ################################################################################
    etcdctl set /node-skydns/local/node/storage/${OPENSTACK_SUBCOMPONENT}/$(hostname -s) "{\"host\":\"${SWIFT_IP}\"}"
    etcdctl set /master-skydns/local/node/storage/${OPENSTACK_SUBCOMPONENT}/$(hostname -s) "{\"host\":\"${SWIFT_IP}\"}"
  fi
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars SWIFT_COMPONENT SWIFT_SUBCOMPONENT


################################################################################
echo "**** SWIFT: ${SWIFT_COMPONENT}-${SWIFT_SUBCOMPONENT} ****"
################################################################################


export cfg=/etc/swift/${SWIFT_COMPONENT}-server.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RUNNING"
################################################################################
/opt/harbor/config-swift-${SWIFT_COMPONENT}.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
if [ "${SWIFT_COMPONENT}" = "proxy" ]
then
  echo "Launching Apache"
  exec httpd -D FOREGROUND
else
  echo "/usr/bin/swift-${SWIFT_COMPONENT}-${SWIFT_SUBCOMPONENT} /etc/swift/${SWIFT_COMPONENT}-server.conf"
  exec su -s /bin/sh -c "exec /usr/bin/swift-${SWIFT_COMPONENT}-${SWIFT_SUBCOMPONENT} /etc/swift/${SWIFT_COMPONENT}-server.conf --verbose" swift
fi
