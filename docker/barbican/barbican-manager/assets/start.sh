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

export cfg=/etc/barbican/barbican.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SETUP"
################################################################################
/opt/harbor/barbican/write-openrc-admin.sh
/opt/harbor/barbican/config-database.sh
/opt/harbor/barbican/create-db.sh
/opt/harbor/barbican/ipa-endpoint-manager.sh
/opt/harbor/barbican/ipa-kra-manager.sh
/opt/harbor/barbican/keystone-endpoint-manager.sh


#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE
