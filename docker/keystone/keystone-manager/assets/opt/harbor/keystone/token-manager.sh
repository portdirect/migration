#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=tokens
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TOKENS"
################################################################################
crudini --set $cfg token provider "fernet"
crudini --set $cfg token driver "sql"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Component Variables"
################################################################################
OPENSTACK_KUBE_SVC_NAME="keystone"
OPENSTACK_KUBE_SVC_NAMESPACE="os-keystone"
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
mkdir -p ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}
KUBE_SVC_KEY_LOC=/etc/keystone/fernet-keys/0
KUBE_SVC_CRT_LOC=/etc/keystone/fernet-keys/1


retreive_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RETREVING SERVICE CIRT"
  ################################################################################

  if ls ${KUBE_SVC_KEY_LOC} ; then
      echo "Key Found"
  else
      echo "Command failed"
      return 1
  fi
  if ls ${KUBE_SVC_CRT_LOC} ; then
      echo "Key Found"
  else
      echo "Command failed"
      return 1
  fi
}


generate_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING SERVICE CIRT"
  ################################################################################
  keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
  chown -R keystone:keystone /var/log/keystone
}


get_service_cirt () {
  ( retreive_service_cirt ) || ( generate_service_cirt &&  retreive_service_cirt )
}


generate_kube_secret_def () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING KUBE SECRET DEF"
  ################################################################################
cat > ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-fernet-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${OPENSTACK_KUBE_SVC_NAME}-fernet-secret
  namespace: ${OPENSTACK_KUBE_SVC_NAMESPACE}
type: Opaque
data:
  0: $( cat ${KUBE_SVC_KEY_LOC} | base64 --wrap=0 )
  1: $( cat ${KUBE_SVC_CRT_LOC} | base64 --wrap=0 )
EOF
}


retreive_kubeconfig () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: OBTAINING KUBECONFIG FROM IPA SERVER"
  ################################################################################
  docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/kubelet/kubeconfig.yaml > ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/kubeconfig.yaml
}

kubectl_helper () {
  CMD=$@
  kubectl --kubeconfig="${SVC_AUTH_ROOT_LOCAL_CONTAINER}/kubeconfig.yaml" --server="https://kubernetes.${OS_DOMAIN}" ${CMD}
}


create_kube_service_cirt_and_secret () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ATTEMPTING TO CREATE SERVICE AND SECRET"
  ################################################################################
  get_service_cirt
  generate_kube_secret_def
  kubectl_helper create -f ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-fernet-secret.yaml
  rm -rf ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-fernet-secret.yaml
  kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-fernet-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE}
}


delete_kube_secret () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DELETING SERVICE SECRET"
  ################################################################################
  get_service_cirt
  generate_kube_secret_def
  kubectl_helper delete -f ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-fernet-secret.yaml
}




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: STARTING SERVICE ENPOINT MANAGEMENT"
################################################################################
retreive_kubeconfig

#delete_kube_secret
kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-fernet-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE} || \
  create_kube_service_cirt_and_secret


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: CLEANING UP"
################################################################################
rm -rf ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/*
