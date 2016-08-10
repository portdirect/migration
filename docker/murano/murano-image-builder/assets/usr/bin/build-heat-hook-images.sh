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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Updating Template to Use IPA-CA Cert"
################################################################################
IPA_CA_CRT="$(cat /etc/ipa/ca.crt | base64 --wrap=0)"
sed -i "s/{{IPA_CA_CRT}}/${IPA_CA_CRT}/" /opt/openstack-diskimage-builder/harbor/elements/heat-config/install.d/99-harbor-ca


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Writing Sourcing OPENRC"
################################################################################
source /openrc_${MURANO_KEYSTONE_USER}-default
openstack token issue


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Exporting BUILD ENV VARS"
################################################################################
ELEMENTS_ROOT=/opt/openstack-diskimage-builder

export PATH="${ELEMENTS_ROOT}/dib-utils/bin:$PATH"
#export ELEMENTS_PATH=${ELEMENTS_ROOT}/tripleo-image-elements/elements:${ELEMENTS_ROOT}/heat-templates/hot/software-config/elements:${ELEMENTS_ROOT}/murano/contrib/elements:${ELEMENTS_ROOT}/murano-agent/contrib/elements
export ELEMENTS_PATH=${ELEMENTS_ROOT}/tripleo-image-elements/elements:${ELEMENTS_ROOT}/harbor/elements:${ELEMENTS_ROOT}/murano/contrib/elements:${ELEMENTS_ROOT}/murano-agent/contrib/elements

export DISTRO_NAME=centos7
export DIB_RELEASE=7
export DIB_DEFAULT_INSTALLTYPE=package


export IMAGE_DISTRO=centos
export IMAGE_FORMAT=qcow2
export HYPERVISOR=kvm
export KERNEL=4.5.2-1.el7.elrepo


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Movinf into /tmp to run builds"
################################################################################
cd /tmp
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Images"
################################################################################
for HOOK in docker-compose script ansible cfn-init puppet salt
do
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing $HOOK Image"
  ################################################################################
  openstack image show ${IMAGE_DISTRO}-heat-${HOOK} || (
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Building ${IMAGE_DISTRO}-heat-${HOOK}"
  ################################################################################
  #${ELEMENTS_ROOT}/diskimage-builder/bin/
  disk-image-create vm \
    centos7 \
    epel \
    selinux-permissive \
    kernel-ml \
    openstack-repo \
    os-collect-config \
    os-refresh-config \
    os-apply-config \
    heat-config \
    heat-config-script \
    heat-config-$HOOK \
    -o /tmp/${IMAGE_DISTRO}-heat-${HOOK}.${IMAGE_FORMAT}

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Uploading ${IMAGE_DISTRO}-heat-${HOOK}"
    ################################################################################
    openstack --insecure image delete ${IMAGE_DISTRO}-heat-${HOOK} || true
    IMAGE_ID=$(openstack --insecure image create \
              --public \
              --file "/tmp/${IMAGE_DISTRO}-heat-${HOOK}.${IMAGE_FORMAT}" \
              --min-disk "2" \
              --min-ram "512" \
              --property "os_distro=${IMAGE_DISTRO}" \
              --property "os_admin_user=${IMAGE_DISTRO}" \
              --property "os_version=${DIB_RELEASE}" \
              --property "hypervisor_type=${HYPERVISOR}" \
              --property "sw_heat_hook=${HOOK}" \
              --property murano_image_info="{\"type\": \"linux\", \"title\": \"${HOOK}-${IMAGE_DISTRO}-${HYPERVISOR}\"}" \
              --disk-format "${IMAGE_FORMAT}" \
              ${IMAGE_DISTRO}-heat-${HOOK} -f value -c id)
    openstack --insecure image show ${IMAGE_ID}

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Cleaning Up ${IMAGE_DISTRO}-heat-${HOOK} build"
    ################################################################################
    rm -f /tmp/${IMAGE_DISTRO}-heat-${HOOK}.${IMAGE_FORMAT}
    )
done
