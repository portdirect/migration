#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=trove-mysql
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh



for cfg in /etc/trove/trove.conf /etc/trove/trove-taskmanager.conf; do
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT} Config: $cfg"
  ################################################################################
  crudini --set $cfg mysql volume_support "False"
  crudini --set $cfg mysql device_path ""
done



for cfg in /etc/trove/trove.conf /etc/trove/trove-taskmanager.conf; do
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT} Config: $cfg"
  ################################################################################
  crudini --set $cfg mariadb volume_support "False"
  crudini --set $cfg mariadb device_path ""
done


for cfg in /etc/trove/trove.conf /etc/trove/trove-taskmanager.conf; do
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT} Config: $cfg"
  ################################################################################
  crudini --set $cfg mongodb volume_support "False"
  crudini --set $cfg mongodb device_path ""
done
