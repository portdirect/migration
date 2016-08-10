#!/bin/bash
set -e
################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital Images"
################################################################################
source /openrc_nova
IMAGE_DISTRO=ubuntu
IMAGE_NAME=docker.io/port/ubuntu:latest
IMAGE_FORMAT=raw
HYPERVISOR=docker
docker pull ${IMAGE_NAME}
docker save ${IMAGE_NAME} > ./docker.tar
openstack image delete ${IMAGE_NAME} || true
IMAGE_ID=$(openstack image create \
          --public \
          --file "./docker.tar" \
          --min-disk "1" \
          --min-ram "64" \
          --property "os_distro=${IMAGE_DISTRO}" \
          --property "os_admin_user=${IMAGE_DISTRO}" \
          --property "os_version=16.04" \
          --property "hypervisor_type=${HYPERVISOR}" \
          --disk-format "${IMAGE_FORMAT}" \
          --container-format "docker" \
          ${IMAGE_NAME} -f value -c id)
openstack image show ${IMAGE_ID}
rm -f ./docker.tar

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital Images"
################################################################################
IMAGE_DISTRO=centos
IMAGE_NAME=docker.io/port/centos:latest
IMAGE_FORMAT=raw
HYPERVISOR=docker
docker pull ${IMAGE_NAME}
docker save ${IMAGE_NAME} > ./docker.tar
openstack image delete ${IMAGE_NAME} || true
IMAGE_ID=$(openstack image create \
          --public \
          --file "./docker.tar" \
          --min-disk "1" \
          --min-ram "64" \
          --property "os_distro=${IMAGE_DISTRO}" \
          --property "os_admin_user=${IMAGE_DISTRO}" \
          --property "os_version=7" \
          --property "hypervisor_type=${HYPERVISOR}" \
          --disk-format "${IMAGE_FORMAT}" \
          --container-format "docker" \
          ${IMAGE_NAME} -f value -c id)
openstack image show ${IMAGE_ID}
rm -f ./docker.tar
