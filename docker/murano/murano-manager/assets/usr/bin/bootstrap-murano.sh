#!/bin/bash
set -e
################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env
source /openrc_${MURANO_KEYSTONE_USER}

################################################################################
echo "${OS_DISTRO}: Checking web can get a token from keystone"
################################################################################
openstack token issue

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/config-murano.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Loading Murano Base Package"
################################################################################
murano-manage --config-file /etc/murano/murano.conf import-package /opt/murano-harbor/meta/io.murano


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Loading Applicatio Packages"
################################################################################
murano-manage --config-file /etc/murano/murano.conf import-package /opt/murano-apps/ansible
murano-manage --config-file /etc/murano/murano.conf import-package /opt/murano-apps/docker-compose
murano-manage --config-file /etc/murano/murano.conf import-package /opt/murano-apps/kubelet
murano-manage --config-file /etc/murano/murano.conf import-package /opt/murano-apps/puppet
murano-manage --config-file /etc/murano/murano.conf import-package /opt/murano-apps/salt


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating Murano Agent Image"
################################################################################
IMAGE_DISTRO=ubuntu
IMAGE_NAME=docker.io/port/ubuntu-murano:latest
IMAGE_FORMAT=raw
HYPERVISOR=docker
docker pull ${IMAGE_NAME}
docker save ${IMAGE_NAME} > ./docker.tar
openstack image delete ${IMAGE_NAME} || true
IMAGE_ID=$(openstack image create \
          --public \
          --file "./docker.tar" \
          --property "os_distro=${IMAGE_DISTRO}" \
          --property "os_admin_user=${IMAGE_DISTRO}" \
          --property "os_version=16.04" \
          --property "hypervisor_type=${HYPERVISOR}" \
          --property murano_image_info="{\"title\": \"${IMAGE_NAME}\", \"type\": \"linux\"}" \
          --disk-format "${IMAGE_FORMAT}" \
          --container-format "docker" \
          ${IMAGE_NAME} -f value -c id)
openstack image show ${IMAGE_ID}
