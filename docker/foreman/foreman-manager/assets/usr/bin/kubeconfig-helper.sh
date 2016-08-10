#!/bin/bash
set -e
OPENSTACK_COMPONENT="KubeConfig Helper"
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Component Variables"
################################################################################
OPENSTACK_KUBE_SVC_NAME="foreman"
OPENSTACK_KUBE_SVC_NAMESPACE="os-${OPENSTACK_KUBE_SVC_NAME}"
OPENSTACK_KUBE_SVC_IP="$(dig +short ${OPENSTACK_KUBE_SVC_NAME}.gantry.svc.${OS_DOMAIN})"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: UPDATING HOSTS FILE"
################################################################################
CONTAINER_IP=$(ip -f inet -o addr show eth0 |cut -d\  -f 7 | cut -d/ -f 1)
cat > /etc/hosts <<EOF
# HarborOS Managed Hosts File
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
fe00::0 ip6-mcastprefix
fe00::1 ip6-allnodes
fe00::2 ip6-allrouters
${CONTAINER_IP} $(hostname -s).${OS_DOMAIN} $(hostname -s)
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DEFINING IPA DOCKER INTERACTION"
################################################################################
FREEIPA_CONTAINER_NAME=$(cat /etc/ipa/default.conf | grep "^server =" | awk '{print $NF}' | sed "s/.${OS_DOMAIN}//")
SVC_AUTH_ROOT_IPA_CONTAINER=/data/harbor/auth
SVC_AUTH_ROOT_LOCAL_CONTAINER=/etc/harbor/auth
mkdir -p $SVC_AUTH_ROOT_LOCAL_CONTAINER



retreive_kubeconfig () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: OBTAINING KUBECONFIG FROM IPA SERVER"
  ################################################################################
  docker -H unix:///run/docker-ipa.sock exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/kubelet/kubeconfig.yaml > ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/kubeconfig.yaml
}

kubectl_helper () {
  CMD=$@
  kubectl --kubeconfig="${SVC_AUTH_ROOT_LOCAL_CONTAINER}/kubeconfig.yaml" --server="https://kubernetes.${OS_DOMAIN}" ${CMD}
}



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: STARTING SERVICE ENPOINT MANAGEMENT"
################################################################################
retreive_kubeconfig
