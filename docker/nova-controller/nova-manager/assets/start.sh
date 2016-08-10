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
. /opt/harbor/config-nova.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars NOVA_DB_NAME NOVA_DB_USER NOVA_DB_PASSWORD ETCDCTL_ENDPOINT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db
fail_unless_os_service_running keystone


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Database"
################################################################################
/usr/bin/create-db.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Keystone"
################################################################################
/usr/bin/write-openrc-admin.sh
/usr/bin/keystone-endpoint-manager.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing IPA"
################################################################################
/usr/bin/ipa-endpoint-manager.sh
/usr/bin/ipa-endpoint-manager-ec2.sh
/usr/bin/ipa-endpoint-manager-metadata.sh
/usr/bin/ipa-endpoint-manager-novnc.sh
/usr/bin/ipa-endpoint-manager-serial.sh
/usr/bin/ipa-endpoint-manager-spice.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Loading Images"
################################################################################
/usr/bin/load-images.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Management Complete"
################################################################################
