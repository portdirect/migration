#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

KUBERNETES_IMAGE="https://fedorapeople.org/groups/mistral/fedora-21-atomic-5.qcow2"
COREOS_IMAGE="http://stable.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2"

MESOS_IMAGE="https://fedorapeople.org/groups/mistral/ubuntu-14.04.3-mesos-0.25.0.qcow2"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars MISTRAL_KEYSTONE_USER MISTRAL_KEYSTONE_PASSWORD \
                    MISTRAL_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_os_service_running keystone

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting API to become active"
################################################################################
source /openrc
export OS_TENANT_NAME="${OS_PROJECT_NAME}"
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_OLD_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v3"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Launching Bootstraper"
################################################################################

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
    ################################################################################
    openstack image show Fedora-Atomic-21 || (
      HYPERVISOR=kvm
      curl --insecure -L ${KUBERNETES_IMAGE} > /tmp/Fedora-Atomic-21.qcow2
      openstack image create \
                --public \
                --protected \
                --property description="Fedora-Atomic Image for Mistral" \
                --property "os_distro=fedora-atomic" \
                --property "os_version=21" \
                --property "os_admin_user=fedora" \
                --property "hypervisor_type=${HYPERVISOR}" \
                --min-disk 2 \
                --min-ram 1024 \
                --disk-format "qcow2" \
                --file "/tmp/Fedora-Atomic-21.qcow2" \
                Fedora-Atomic-21
      rm -f /tmp/Fedora-Atomic-21.qcow2
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
                --property description="CoreOS Image for Mistral" \
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
                --property description="Ubuntu Image for Mistral" \
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
    mistral service-list
    mistral baymodel-list


NEUTRON_EXTRNAL_NET=$(neutron net-show External -f value -c id)


cd /tmp

SSH_KEY_NAME=harbor-swarm
ssh-keygen -N "" -t rsa -f ./${SSH_KEY_NAME}.key
openstack container show mistral || openstack container create mistral
openstack object show  mistral ${SSH_KEY_NAME}.key || openstack object create mistral ${SSH_KEY_NAME}.key
openstack object show  mistral ${SSH_KEY_NAME}.key.pub || openstack object create mistral ${SSH_KEY_NAME}.key.pub
openstack keypair show ${SSH_KEY_NAME} || openstack keypair create --public-key ${SSH_KEY_NAME}.key.pub ${SSH_KEY_NAME}

    mistral baymodel-create --name swarm-kvm-no-tls \
                       --image-id Fedora-Atomic-21 \
                       --keypair-id ${SSH_KEY_NAME} \
                       --external-network-id ${NEUTRON_EXTRNAL_NET} \
                       --dns-nameserver 8.8.8.8 \
                       --flavor-id m1.small \
                       --docker-volume-size 5 \
                       --tls-disabled \
                       --coe swarm


mistral bay-create --name swarm-kvm-no-tls --baymodel swarm-kvm-no-tls --node-count 1
mistral container-create --name test-container \
                        --image docker.io/cirros:latest \
                        --bay swarm-kvm-no-tls \
                        --command "ping -c 4 8.8.8.8"
mistral container-start test-container
mistral container-logs test-container
mistral container-delete test-container


mistral container-create --name test-nginx \
                        --image docker.io/nginx:latest \
                        --bay swarm-kvm-no-tls
mistral container-start test-nginx
mistral container-logs test-nginx
mistral container-stop test-nginx
mistral container-delete test-nginx

mistral bay-delete swarm-kvm-no-tls




mistral baymodel-create --name k8s-kvm-no-tls \
                       --image-id Fedora-Atomic-21 \
                       --keypair-id ${SSH_KEY_NAME} \
                       --external-network-id ${NEUTRON_EXTRNAL_NET} \
                       --dns-nameserver 8.8.8.8 \
                       --flavor-id m1.small \
                       --docker-volume-size 5 \
                       --network-driver flannel \
                       --coe kubernetes \
                       --tls-disabled \
                       --public
mistral bay-create --name k8s-kvm-no-tls --baymodel k8s-kvm-no-tls --node-count 1
wget --no-check-certificate https://github.com/kubernetes/kubernetes/releases/download/v1.0.1/kubernetes.tar.gz
tar -xvzf kubernetes.tar.gz
cd kubernetes/examples/redis
mistral pod-create --manifest ./redis-master.yaml --bay k8s-kvm-no-tls
mistral coe-service-create --manifest ./redis-sentinel-service.yaml --bay k8s-kvm-no-tls
sed -i 's/\(replicas: \)1/\1 2/' redis-controller.yaml
mistral rc-create --manifest ./redis-controller.yaml --bay k8s-kvm-no-tls

sed -i 's/\(replicas: \)1/\1 2/' redis-sentinel-controller.yaml
mistral rc-create --manifest ./redis-sentinel-controller.yaml --bay k8s-kvm-no-tls
mistral bay-show k8s-kvm-no-tls
mistral bay-delete k8s-kvm-no-tls
cd /








mistral baymodel-create --name mesos-kvm-no-tls \
                       --image-id Ubuntu-14.04-Mesos \
                       --keypair-id ${SSH_KEY_NAME} \
                       --external-network-id ${NEUTRON_EXTRNAL_NET} \
                       --dns-nameserver 8.8.8.8 \
                       --flavor-id m1.small \
                       --tls-disabled \
                       --coe mesos

mistral bay-create --name mesos-kvm-no-tls --baymodel mesos-kvm-no-tls --node-count 2

mistral bay-show mesos-kvm-no-tls






################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Bootstrapper Complete"
################################################################################
