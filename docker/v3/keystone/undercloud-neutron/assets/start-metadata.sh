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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Nova Metadata API"
################################################################################
wait-http $NOVA_METADATA_SERVICE_HOST:8775


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Removing any existing router namespaces"
################################################################################
ip netns list | grep qmeta | while read -r line ; do
  ip netns delete $line
done
ip netns list | grep qmeta | while read -r line ; do
  ip netns delete $line
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
(
until neutron-ovn-metadata-agent --config-file $cfg --config-file $cfg_metadata_ovn --debug; do
    echo "neutron-ovn-metadata-agent crashed with exit code $?.  Respawning.." >&2
    sleep 1s
done
)&
sleep 5s
neutron-metadata-agent --config-file $cfg --config-file $cfg_metadata --debug
