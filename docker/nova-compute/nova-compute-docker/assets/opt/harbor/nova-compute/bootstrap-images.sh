source openrc

 docker.io/port/centos:latest



echo "--------------------------------------------------------------"
echo "${OS_DISTRO}: ${RELEASE}: BUILDING IMAGES"
echo "--------------------------------------------------------------"
#SERVICE_TYPES="cassandra couchbase couchdb db2 mariadb mongodb mysql percona postgresql pxc redis vertica"
#export SERVICE_TYPES='cassandra couchbase couchdb mariadb mongodb mysql percona postgresql pxc redis'
export IMAGES='docker.io/port/centos:latest'

for IMAGE in ${IMAGES}; do
  source /openrc
  IMAGE_NAME=${IMAGE}
  IMAGE_FORMAT=raw
  HYPERVISOR=docker
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
  ################################################################################
    docker pull ${IMAGE_NAME}
    docker save ${IMAGE_NAME} > /tmp/docker.tar
    source /openrc
    openstack image delete ${IMAGE_NAME}
    IMAGE_ID=$(openstack image create \
              --public \
              --file "/tmp/docker.tar" \
              --property "os_distro=centos" \
              --property "os_admin_user=centos" \
              --property "os_version=7" \
              --property "hypervisor_type=${HYPERVISOR}" \
              --disk-format "${IMAGE_FORMAT}" \
              --container-format "docker" \
              ${IMAGE_NAME} -f value -c id)
    openstack image show ${IMAGE_ID}
done
