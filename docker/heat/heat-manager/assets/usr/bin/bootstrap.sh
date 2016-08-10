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

: ${CINDER_API_SERVICE_PORT:="8776"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME


check_required_vars CINDER_KEYSTONE_USER CINDER_KEYSTONE_PASSWORD \
                    CINDER_API_SERVICE_HOST CINDER_API_SERVICE_PORT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_os_service_running keystone

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting API to become active"
################################################################################
source /openrc


################################################################################
echo "${OS_DISTRO}: cinder: Launching Bootstraper"
################################################################################

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
    ################################################################################
    VOLUME_TYPE_NAME="GlusterFS"
    (cinder type-list | awk '{print $4}' | grep -q "${VOLUME_TYPE_NAME}") || \
      cinder type-create "${VOLUME_TYPE_NAME}" --description "${OS_DISTRO} GlusterFS" --is-public "True"
    cinder type-key "${VOLUME_TYPE_NAME}" set "volume_backend_name=GlusterfsDriver"
    cinder type-list
    cinder extra-specs-list

################################################################################
echo "${OS_DISTRO}: Cinder: Bootstrapper Complete"
################################################################################
