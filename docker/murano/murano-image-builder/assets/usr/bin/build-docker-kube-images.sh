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
export ELEMENTS_PATH=${ELEMENTS_ROOT}/diskimage-builder/elements:${ELEMENTS_ROOT}/murano/contrib/elements:${ELEMENTS_ROOT}/murano-agent/contrib/elements:${ELEMENTS_ROOT}/murano-apps/Docker/DockerStandaloneHost/elements


export DISTRO_NAME=ubuntu
export DIB_RELEASE=xenial
export DIB_DEFAULT_INSTALLTYPE=package


export IMAGE_DISTRO=ubuntu
export IMAGE_FORMAT=qcow2
export HYPERVISOR=kvm



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Movinf into /tmp to run builds"
################################################################################
cd /tmp


HOOK=docker
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing $HOOK Image"
################################################################################
openstack image show ${IMAGE_DISTRO}-murano-${HOOK} || (
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up teplates for ${IMAGE_DISTRO}-heat-${HOOK}"
################################################################################
rm -f ${ELEMENTS_ROOT}/murano-apps/Docker/DockerStandaloneHost/elements/${HOOK}/install.d/99-harbor-ca || true
cp ${ELEMENTS_ROOT}/harbor/elements/heat-config/install.d/99-harbor-ca ${ELEMENTS_ROOT}/murano-apps/Docker/DockerStandaloneHost/elements/${HOOK}/install.d/
ln -s ${ELEMENTS_ROOT}/diskimage-builder/elements/ubuntu ${ELEMENTS_ROOT}/murano/contrib/elements/ubuntu
cat > ${ELEMENTS_ROOT}/murano/contrib/elements/ubuntu/pre-install.d/02-install-python <<EOF
#!/bin/bash
if [ \${DIB_DEBUG_TRACE:-1} -gt 0 ]; then
    set -x
fi
set -eu
set -o pipefail

apt-get -y update
apt-get install -y python python-pip
pip install --upgrade pip
pip install virtualenv
EOF
chmod +x ${ELEMENTS_ROOT}/murano/contrib/elements/ubuntu/pre-install.d/02-install-python


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Building ${IMAGE_DISTRO}-heat-${HOOK}"
################################################################################
disk-image-create vm \
  ubuntu \
  murano-agent \
  ${HOOK} \
  -o /tmp/${IMAGE_DISTRO}-murano-${HOOK}.${IMAGE_FORMAT}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Uploading ${IMAGE_DISTRO}-heat-${HOOK}"
################################################################################
openstack --insecure image delete ${IMAGE_DISTRO}-murano-${HOOK} || true
IMAGE_ID=$(openstack --insecure image create \
          --public \
          --file "/tmp/${IMAGE_DISTRO}-murano-${HOOK}.${IMAGE_FORMAT}" \
          --min-disk "2" \
          --min-ram "512" \
          --property "os_distro=${IMAGE_DISTRO}" \
          --property "os_admin_user=${IMAGE_DISTRO}" \
          --property "os_version=${DIB_RELEASE}" \
          --property "hypervisor_type=${HYPERVISOR}" \
          --property murano_image_info="{\"type\": \"linux\", \"title\": \"${HOOK}-${IMAGE_DISTRO}-${HYPERVISOR}\"}" \
          --disk-format "${IMAGE_FORMAT}" \
          ${IMAGE_DISTRO}-murano-${HOOK} -f value -c id)
openstack --insecure image show ${IMAGE_ID}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Cleaning Up ${IMAGE_DISTRO}-heat-${HOOK} build"
################################################################################
rm -f /tmp/${IMAGE_DISTRO}-murano-${HOOK}.${IMAGE_FORMAT}
)








HOOK=kubernetes
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing $HOOK Image"
################################################################################
openstack image show ${IMAGE_DISTRO}-murano-${HOOK} || (
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting up teplates for ${IMAGE_DISTRO}-heat-${HOOK}"
################################################################################
rm -f ${ELEMENTS_ROOT}/murano-apps/Docker/DockerStandaloneHost/elements/${HOOK}/install.d/99-harbor-ca || true
mkdir -p ${ELEMENTS_ROOT}/murano-apps/Docker/DockerStandaloneHost/elements/${HOOK}/install.d
cp ${ELEMENTS_ROOT}/harbor/elements/heat-config/install.d/99-harbor-ca ${ELEMENTS_ROOT}/murano-apps/Docker/DockerStandaloneHost/elements/${HOOK}/install.d/
ln -s ${ELEMENTS_ROOT}/diskimage-builder/elements/ubuntu ${ELEMENTS_ROOT}/murano/contrib/elements/ubuntu || true

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Building ${IMAGE_DISTRO}-heat-${HOOK}"
################################################################################
disk-image-create vm \
  ubuntu \
  murano-agent \
  ${HOOK} \
  -o /tmp/${IMAGE_DISTRO}-murano-${HOOK}.${IMAGE_FORMAT}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Uploading ${IMAGE_DISTRO}-heat-${HOOK}"
################################################################################
openstack --insecure image delete ${IMAGE_DISTRO}-heat-${HOOK} || true
IMAGE_ID=$(openstack --insecure image create \
          --public \
          --file "/tmp/${IMAGE_DISTRO}-murano-${HOOK}.${IMAGE_FORMAT}" \
          --min-disk "2" \
          --min-ram "512" \
          --property "os_distro=${IMAGE_DISTRO}" \
          --property "os_admin_user=${IMAGE_DISTRO}" \
          --property "os_version=${DIB_RELEASE}" \
          --property "hypervisor_type=${HYPERVISOR}" \
          --property murano_image_info="{\"type\": \"linux\", \"title\": \"${HOOK}-${IMAGE_DISTRO}-${HYPERVISOR}\"}" \
          --disk-format "${IMAGE_FORMAT}" \
          ${IMAGE_DISTRO}-murano-${HOOK} -f value -c id)
openstack --insecure image show ${IMAGE_ID}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Cleaning Up ${IMAGE_DISTRO}-heat-${HOOK} build"
################################################################################
rm -f /tmp/${IMAGE_DISTRO}-murano-${HOOK}.${IMAGE_FORMAT}
)
