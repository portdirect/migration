#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

MANILA_IMAGE="http://tarballs.openstack.org/manila-image-elements/images/manila-service-image-refs-tags-1.2.0.qcow2"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

MANILA_SERVICE_VM_FLAVOR_REF=${MANILA_SERVICE_VM_FLAVOR_REF:-100}
MANILA_SERVICE_VM_FLAVOR_NAME=${MANILA_SERVICE_VM_FLAVOR_NAME:-"manila-service-flavor"}
MANILA_SERVICE_VM_FLAVOR_RAM=${MANILA_SERVICE_VM_FLAVOR_RAM:-128}
MANILA_SERVICE_VM_FLAVOR_DISK=${MANILA_SERVICE_VM_FLAVOR_DISK:-0}
MANILA_SERVICE_VM_FLAVOR_VCPUS=${MANILA_SERVICE_VM_FLAVOR_VCPUS:-1}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars MANILA_KEYSTONE_USER MANILA_KEYSTONE_PASSWORD


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_os_service_running keystone

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting API to become active"
################################################################################
source /openrc
#export OS_TENANT_NAME="${OS_PROJECT_NAME}"
#export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_OLD_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v3"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Launching Bootstraper"
################################################################################

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
    ################################################################################
    HYPERVISOR=kvm
    ( openstack image show Manila-Server && sleep 15s ) || (
      curl --insecure -L ${MANILA_IMAGE} | openstack image create \
                --public \
                --protected \
                --property "os_distro=ubuntu" \
                --disk-format "qcow2" \
                --min-disk "1" \
                --min-ram "64" \
                --property "os_admin_user=ubuntu" \
                --property "os_version=7" \
                --property "hypervisor_type=${HYPERVISOR}" \
                Manila-Server
    )

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Image Flavour"
    ################################################################################
    nova flavor-show $MANILA_SERVICE_VM_FLAVOR_NAME || nova flavor-create \
        $MANILA_SERVICE_VM_FLAVOR_NAME \
        $MANILA_SERVICE_VM_FLAVOR_REF \
        $MANILA_SERVICE_VM_FLAVOR_RAM \
        $MANILA_SERVICE_VM_FLAVOR_DISK \
        $MANILA_SERVICE_VM_FLAVOR_VCPUS \
        --is-public 'True'

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Share Types"
    ################################################################################
    MANILA_SHARE_BACKEND1_NAME="default"
    manila --debug type-create "${MANILA_SHARE_BACKEND1_NAME}" True || true
    manila --debug type-list


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Bootstrapper Complete"
################################################################################
