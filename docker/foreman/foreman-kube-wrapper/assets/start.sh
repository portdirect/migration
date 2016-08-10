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



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars ETCDCTL_ENDPOINT


BRIDGE_DEVICE=$PROXY_BRIDGE
BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
IP=$(echo ${BRIDGE_IP} | awk -F. '{print $1"."$2"."$3".10"}')
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Cleaning Up any old container"
################################################################################
docker stop foreman-proxy-${BRIDGE_DEVICE} || true
docker rm foreman-proxy-${BRIDGE_DEVICE} || true
ip link del dhcp_${BRIDGE_DEVICE} || true
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching Container"
################################################################################
cat /etc/os-container.env > /var/lib/harbor/foreman/proxy-${BRIDGE_DEVICE}.env
docker run -d -t \
--name foreman-proxy-${BRIDGE_DEVICE} \
--hostname foreman-proxy-${BRIDGE_DEVICE}.port.direct \
--privileged \
-v /var/lib/harbor/foreman/proxy-${BRIDGE_DEVICE}.env:/etc/os-config/openstack.env:ro \
-v /var/lib/harbor/foreman/pod:/var/pod:rw \
-v /var/lib/harbor/foreman/proxy-${BRIDGE_DEVICE}/tftpboot:/var/lib/tftpboot:rw \
-v /var/lib/harbor/foreman/proxy-${BRIDGE_DEVICE}/puppet:/var/lib/puppet/ssl:rw \
port/foreman-proxy:latest /sbin/init
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Connecting Container to ${BRIDGE_DEVICE} with the address ${IP}/16"
################################################################################
pipework ${BRIDGE_DEVICE} -i ${BRIDGE_DEVICE} -l dhcp_${BRIDGE_DEVICE} foreman-proxy-${BRIDGE_DEVICE} ${IP}/16
docker logs -f foreman-proxy-${BRIDGE_DEVICE}
