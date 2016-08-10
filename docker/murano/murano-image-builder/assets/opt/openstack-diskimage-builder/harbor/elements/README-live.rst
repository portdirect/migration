============================
Software configuration hooks
============================

This directory contains `diskimage-builder <https://github.com/openstack/diskimage-builder>`_
elements to build an image which contains the software configuration hook
required to use your preferred configuration method.

These elements depend on some elements found in the
`tripleo-image-elements <https://github.com/openstack/tripleo-image-elements>`_
repository. These elements will build an image which uses
`os-collect-config <https://github.com/openstack/os-collect-config>`_,
`os-refresh-config <https://github.com/openstack/os-refresh-config>`_, and
`os-apply-config <https://github.com/openstack/os-apply-config>`_ together to
invoke a hook with the supplied configuration data, and return any outputs back
to heat.

When building an image only the elements for the preferred configuration methods are required. The heat-config element is automatically included as a dependency.

An example fedora based image containing all hooks can be built and uploaded to glance
with the following:

::

git clone https://git.openstack.org/openstack/diskimage-builder.git
git clone https://git.openstack.org/openstack/tripleo-image-elements.git
git clone https://git.openstack.org/openstack/heat-templates.git
git clone https://git.openstack.org/openstack/dib-utils.git
git clone git://git.openstack.org/openstack/murano
git clone git://git.openstack.org/openstack/murano-agent

export PATH="${PWD}/dib-utils/bin:$PATH"
export ELEMENTS_PATH=${PWD}/tripleo-image-elements/elements:${PWD}/heat-templates/hot/software-config/elements:${PWD}/murano/contrib/elements:${PWD}/murano-agent/contrib/elements
export DISTRO_NAME=centos7
export DIB_RELEASE=7
export DIB_DEFAULT_INSTALLTYPE=package


export IMAGE_DISTRO=centos
export IMAGE_FORMAT=qcow2
export HYPERVISOR=kvm
export KERNEL=4.5.2-1.el7.elrepo

for HOOK in kubelet
for HOOK in docker-compose script ansible cfn-init puppet salt
do
  echo $HOOK  # Each planet on a separate line.
  /home/harbor/Documents/Builder/DISKIMAGE_BUILDER/diskimage-builder/bin/disk-image-create vm \
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

    rm -f /tmp/${IMAGE_DISTRO}-heat-${HOOK}.${IMAGE_FORMAT}
done
