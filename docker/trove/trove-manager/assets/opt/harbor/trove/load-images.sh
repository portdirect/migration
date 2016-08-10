#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=image-loader
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

source /openrc

echo "--------------------------------------------------------------"
echo "${OS_DISTRO}: ${RELEASE}: LOADING IMAGES"
echo "--------------------------------------------------------------"
#SERVICE_TYPES="cassandra couchbase couchdb db2 mariadb mongodb mysql percona postgresql pxc redis vertica"
#export SERVICE_TYPES='cassandra couchbase couchdb mariadb mongodb mysql percona postgresql pxc redis'
export IMAGE_DISTRO="centos"
export SERVICE_TYPES='mysql mariadb mongodb'
for SERVICE_TYPE in ${SERVICE_TYPES}; do
  export IMAGES="docker.io/port/centos-${SERVICE_TYPE}:latest"
  for IMAGE in ${IMAGES}; do
    IMAGE_NAME=${IMAGE}
    IMAGE_FORMAT=raw
    HYPERVISOR=docker
    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
    ################################################################################
      docker pull ${IMAGE_NAME}
      docker save ${IMAGE_NAME} > ./docker.tar
      openstack image delete ${IMAGE_NAME} || true
      IMAGE_ID=$(openstack image create \
                --public \
                --file "./docker.tar" \
                --property "os_distro=${IMAGE_DISTRO}" \
                --property "os_admin_user=${IMAGE_DISTRO}" \
                --property "os_version=7" \
                --property "hypervisor_type=${HYPERVISOR}" \
                --disk-format "${IMAGE_FORMAT}" \
                --container-format "docker" \
                ${IMAGE_NAME} -f value -c id)
      rm -f ./docker.tar
      openstack image show ${IMAGE_ID}
      etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${SERVICE_TYPE}/image-id "${IMAGE_ID}"
  done
done
