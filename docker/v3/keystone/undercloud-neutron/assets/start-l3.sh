#!/bin/sh
set -e
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config"
################################################################################
source /opt/config-neutron.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For DB"
################################################################################
wait-mysql

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Public Keystone"
################################################################################
wait-http $KEYSTONE_SERVICE_HOST:5000

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Public Neutron"
################################################################################
wait-http $NEUTRON_SERVICE_HOST:9696


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing any existing router namespaces"
################################################################################
ip netns list | grep qrouter | while read -r line ; do
  ip netns delete $line
done
ip netns list | grep qrouter | while read -r line ; do
  ip netns delete $line
done


if [ "$OVN_L3_MODE" = "True" ]; then
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}:Not launching as native OVN L3 support enabled"
  ################################################################################
  exec tail -f /dev/null
else
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
  ################################################################################
  exec neutron-l3-agent --config-file $cfg --config-file $cfg_l3 --debug
fi;
