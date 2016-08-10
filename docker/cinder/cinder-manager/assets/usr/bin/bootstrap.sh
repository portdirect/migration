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
check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME


check_required_vars CINDER_KEYSTONE_USER CINDER_KEYSTONE_PASSWORD \
                    CINDER_API_SERVICE_HOST


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


    # ################################################################################
    # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
    # ################################################################################
    # VOLUME_TYPE_NAME="GlusterFS-Encrypted"
    # (cinder type-list | awk '{print $4}' | grep -q "${VOLUME_TYPE_NAME}") || \
    #   cinder type-create "${VOLUME_TYPE_NAME}" --description "${OS_DISTRO} ${VOLUME_TYPE_NAME}" --is-public "True"
    # cinder type-key "${VOLUME_TYPE_NAME}" set "volume_backend_name=GlusterfsDriver"
    # cinder encryption-type-show ${VOLUME_TYPE_NAME} || cinder encryption-type-create --cipher aes-xts-plain64 --key_size 512 \
    #   --control_location front-end ${VOLUME_TYPE_NAME} nova.volume.encryptors.luks.LuksEncryptor


    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
    ################################################################################
    VOLUME_TYPE_NAME="LVMVolume"
    (cinder type-list | awk '{print $4}' | grep -q "${VOLUME_TYPE_NAME}") || \
      cinder type-create "${VOLUME_TYPE_NAME}" --description "${OS_DISTRO} LVMVolume" --is-public "True"
    cinder type-key "${VOLUME_TYPE_NAME}" set "volume_backend_name=LVMVolumeDriver"


    # ################################################################################
    # echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
    # ################################################################################
    # VOLUME_TYPE_NAME="LVMVolume-Encrypted"
    # (cinder type-list | awk '{print $4}' | grep -q "${VOLUME_TYPE_NAME}") || \
    #   cinder type-create "${VOLUME_TYPE_NAME}" --description "${OS_DISTRO} ${VOLUME_TYPE_NAME}" --is-public "True"
    # cinder type-key "${VOLUME_TYPE_NAME}" set "volume_backend_name=LVMVolumeDriver"
    # cinder encryption-type-show ${VOLUME_TYPE_NAME} || cinder encryption-type-create --cipher aes-xts-plain64 --key_size 512 \
    #   --control_location front-end ${VOLUME_TYPE_NAME} nova.volume.encryptors.luks.LuksEncryptor

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Volume Types From Cinder"
    ################################################################################
    cinder type-list
    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Volume Extra Specs From Cinder"
    ################################################################################
    cinder extra-specs-list
    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Volume Encrption Types From Cinder"
    ################################################################################
    cinder encryption-type-list


################################################################################
echo "${OS_DISTRO}: Cinder: Bootstrapper Complete"
################################################################################
