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


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}:Configuring"
################################################################################
/opt/harbor/config-gnocchi.sh



chown gnocchi:gnocchi /var/lib/gnocchi
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up endpoints"
################################################################################
/opt/harbor/gnocchi/ipa-endpoint-manager.sh
/opt/harbor/gnocchi/write-openrc-admin.sh
/opt/harbor/gnocchi/keystone-endpoint-manager.sh
/opt/harbor/gnocchi/create-db.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up endpoints: GRAFANA"
################################################################################
/opt/harbor/gnocchi/create-db-grafana.sh
/opt/harbor/gnocchi/ipa-grafana-ldap.sh
/opt/harbor/gnocchi/ipa-endpoint-manager-grafana.sh
/opt/harbor/gnocchi/ipsilon-websso-manager.sh


#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE
