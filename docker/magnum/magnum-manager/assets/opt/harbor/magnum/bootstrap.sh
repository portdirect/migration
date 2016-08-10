#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

KUBERNETES_IMAGE="https://fedorapeople.org/groups/magnum/fedora-atomic-latest.qcow2"
COREOS_IMAGE="http://stable.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2"

MESOS_IMAGE="https://fedorapeople.org/groups/magnum/ubuntu-14.04.3-mesos-0.25.0.qcow2"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars MAGNUM_KEYSTONE_USER MAGNUM_KEYSTONE_PASSWORD \
                    MAGNUM_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_os_service_running keystone

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting API to become active"
################################################################################
source /openrc


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Launching Bootstraper"
################################################################################

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Loading Images"
################################################################################
openstack image show Fedora-Atomic || (
  HYPERVISOR=kvm
  curl --insecure -L ${KUBERNETES_IMAGE} > /tmp/Fedora-Atomic-21.qcow2
  openstack image create \
            --public \
            --protected \
            --property description="Fedora-Atomic Image for Magnum" \
            --property "os_distro=fedora-atomic" \
            --property "os_version=23" \
            --property "os_admin_user=fedora" \
            --property "hypervisor_type=${HYPERVISOR}" \
            --min-disk 2 \
            --min-ram 1024 \
            --disk-format "qcow2" \
            --file "/tmp/Fedora-Atomic-21.qcow2" \
            Fedora-Atomic
  rm -f /tmp/Fedora-Atomic.qcow2
)
openstack image show CoreOS || (
  HYPERVISOR=kvm
  curl -L http://stable.release.core-os.net/amd64-usr/current/version.txt > /tmp/core-version.txt
  source /tmp/core-version.txt
  curl --insecure -L ${COREOS_IMAGE} > /tmp/CoreOS.img.bz2
  bunzip2 /tmp/CoreOS.img.bz2
  openstack image create \
            --public \
            --protected \
            --property description="CoreOS Image for Magnum" \
            --property "os_distro=coreos" \
            --property "os_version=${COREOS_VERSION}" \
            --property "os_admin_user=core" \
            --property "hypervisor_type=${HYPERVISOR}" \
            --min-disk 2 \
            --min-ram 1024 \
            --disk-format "qcow2" \
            --file "/tmp/CoreOS.img" \
            CoreOS
  rm -f /tmp/CoreOS.img*
)
openstack image show Ubuntu-14.04-Mesos || (
  HYPERVISOR=kvm
  curl --insecure -L ${MESOS_IMAGE} > /tmp/Ubuntu-14.04-Mesos.img
  openstack image create \
            --public \
            --protected \
            --property description="Ubuntu Image for Magnum" \
            --property "os_distro=ubuntu" \
            --property "os_version=14.04" \
            --property "os_admin_user=ubuntu" \
            --property "hypervisor_type=${HYPERVISOR}" \
            --min-disk 2 \
            --min-ram 1024 \
            --disk-format "qcow2" \
            --file "/tmp/Ubuntu-14.04-Mesos.img" \
            Ubuntu-14.04-Mesos
  rm -f /tmp/Ubuntu-14.04-Mesos.img
)


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Magnum"
################################################################################
magnum --debug --os-tenant-name ${OS_PROJECT_NAME} service-list
magnum --debug --os-tenant-name ${OS_PROJECT_NAME} baymodel-list


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating swift container to store ssh keys in"
################################################################################
openstack container show magnum || openstack container create magnum


NEUTRON_EXTRNAL_NET=$(neutron net-show External -f value -c id)
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: External Network ID for bays $NEUTRON_EXTRNAL_NET"
################################################################################


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SWARM"
################################################################################
SSH_KEY_NAME=harbor-swarm
echo n | ssh-keygen -N "" -t rsa -f ./${SSH_KEY_NAME}.key
openstack object show  magnum ${SSH_KEY_NAME}.key || openstack object create magnum ${SSH_KEY_NAME}.key
openstack object show  magnum ${SSH_KEY_NAME}.key.pub || openstack object create magnum ${SSH_KEY_NAME}.key.pub
openstack keypair show ${SSH_KEY_NAME} || openstack keypair create --public-key ${SSH_KEY_NAME}.key.pub ${SSH_KEY_NAME}


magnum --os-tenant-name ${OS_PROJECT_NAME} \
      baymodel-show swarm-kvm-no-tls || \
magnum --os-tenant-name ${OS_PROJECT_NAME} \
      baymodel-create --name swarm-kvm-no-tls \
                   --image-id Fedora-Atomic \
                   --keypair-id ${SSH_KEY_NAME} \
                   --external-network-id ${NEUTRON_EXTRNAL_NET} \
                   --dns-nameserver 8.8.8.8 \
                   --flavor-id m1.small \
                   --docker-volume-size 5 \
                   --tls-disabled \
                   --coe swarm \
                   --public


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: K8S"
################################################################################
SSH_KEY_NAME=harbor-k8s
echo n | ssh-keygen -N "" -t rsa -f ./${SSH_KEY_NAME}.key
openstack object show  magnum ${SSH_KEY_NAME}.key || openstack object create magnum ${SSH_KEY_NAME}.key
openstack object show  magnum ${SSH_KEY_NAME}.key.pub || openstack object create magnum ${SSH_KEY_NAME}.key.pub
openstack keypair show ${SSH_KEY_NAME} || openstack keypair create --public-key ${SSH_KEY_NAME}.key.pub ${SSH_KEY_NAME}


magnum --os-tenant-name ${OS_PROJECT_NAME} \
     baymodel-show k8s-kvm-no-tls || \
magnum --os-tenant-name ${OS_PROJECT_NAME} \
     baymodel-create --name k8s-kvm-no-tls \
                      --image-id Fedora-Atomic \
                      --keypair-id ${SSH_KEY_NAME} \
                      --external-network-id ${NEUTRON_EXTRNAL_NET} \
                      --dns-nameserver 8.8.8.8 \
                      --flavor-id m1.small \
                      --docker-volume-size 5 \
                      --network-driver flannel \
                      --coe kubernetes \
                      --tls-disabled \
                      --public


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: MESOS"
################################################################################
SSH_KEY_NAME=harbor-mesos
echo n | ssh-keygen -N "" -t rsa -f ./${SSH_KEY_NAME}.key
openstack object show  magnum ${SSH_KEY_NAME}.key || openstack object create magnum ${SSH_KEY_NAME}.key
openstack object show  magnum ${SSH_KEY_NAME}.key.pub || openstack object create magnum ${SSH_KEY_NAME}.key.pub
openstack keypair show ${SSH_KEY_NAME} || openstack keypair create --public-key ${SSH_KEY_NAME}.key.pub ${SSH_KEY_NAME}


magnum --os-tenant-name ${OS_PROJECT_NAME} \
     baymodel-show mesos-kvm-no-tls || \
magnum --os-tenant-name ${OS_PROJECT_NAME} \
     baymodel-create --name mesos-kvm-no-tls \
                     --image-id Ubuntu-14.04-Mesos \
                     --keypair-id ${SSH_KEY_NAME} \
                     --external-network-id ${NEUTRON_EXTRNAL_NET} \
                     --dns-nameserver 8.8.8.8 \
                     --flavor-id m1.small \
                     --tls-disabled \
                     --coe mesos \
                     --public




# magnum bay-create --name swarm-kvm-no-tls --baymodel swarm-kvm-no-tls --node-count 1
# magnum container-create --name test-container \
#                         --image docker.io/cirros:latest \
#                         --bay swarm-kvm-no-tls \
#                         --command "ping -c 4 8.8.8.8"
# magnum container-start test-container
# magnum container-logs test-container
# magnum container-delete test-container
#
#
# magnum container-create --name test-nginx \
#                         --image docker.io/nginx:latest \
#                         --bay swarm-kvm-no-tls
# magnum container-start test-nginx
# magnum container-logs test-nginx
# magnum container-stop test-nginx
# magnum container-delete test-nginx
#
# magnum bay-delete swarm-kvm-no-tls
#
#
#
#
# magnum bay-create --name k8s-kvm-no-tls --baymodel k8s-kvm-no-tls --node-count 1
# wget --no-check-certificate https://github.com/kubernetes/kubernetes/releases/download/v1.0.1/kubernetes.tar.gz
# tar -xvzf kubernetes.tar.gz
# cd kubernetes/examples/redis
# magnum pod-create --manifest ./redis-master.yaml --bay k8s-kvm-no-tls
# magnum coe-service-create --manifest ./redis-sentinel-service.yaml --bay k8s-kvm-no-tls
# sed -i 's/\(replicas: \)1/\1 2/' redis-controller.yaml
# magnum rc-create --manifest ./redis-controller.yaml --bay k8s-kvm-no-tls
#
# sed -i 's/\(replicas: \)1/\1 2/' redis-sentinel-controller.yaml
# magnum rc-create --manifest ./redis-sentinel-controller.yaml --bay k8s-kvm-no-tls
# magnum bay-show k8s-kvm-no-tls
# magnum bay-delete k8s-kvm-no-tls
# cd /
#
#
#
#
#
#
#
#
#
#
# magnum bay-create --name mesos-kvm-no-tls --baymodel mesos-kvm-no-tls --node-count 2
#
# magnum bay-show mesos-kvm-no-tls






################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Bootstrapper Complete"
################################################################################
