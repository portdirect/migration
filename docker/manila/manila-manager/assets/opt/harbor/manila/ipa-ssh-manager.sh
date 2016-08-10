#!/bin/bash
set -e
OPENSTACK_COMPONENT="IPA-ENDPOINT_MANAGER"
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
OPENSTACK_KUBE_SVC_NAME="manila"
OPENSTACK_KUBE_SVC_NAMESPACE="os-manila"
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
KUBE_SVC_KEY_LOC=${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/id_rsa
KUBE_SVC_CRT_LOC=${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/id_rsa.pub


retreive_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RETREVING SERVICE CIRT"
  ################################################################################

  if docker exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/id_rsa ; then
     docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/id_rsa > ${KUBE_SVC_KEY_LOC}
  else
      echo "Command failed"
      return 1
  fi
  if docker exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/id_rsa.pub ; then
     docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/id_rsa.pub> ${KUBE_SVC_CRT_LOC}
  else
      echo "Command failed"
      return 1
  fi
}


generate_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING SERVICE CIRT"
  ################################################################################
 docker exec ${FREEIPA_CONTAINER_NAME} mkdir -p ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}
 ssh-keygen -N "" -t rsa -f /tmp/id_rsa
 cat /tmp/id_rsa |docker exec -i ${FREEIPA_CONTAINER_NAME} /bin/bash -c "cat > ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/id_rsa"
 cat /tmp/id_rsa.pub |docker exec -i ${FREEIPA_CONTAINER_NAME} /bin/bash -c "cat > ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/id_rsa.pub"
 retreive_service_cirt
}



generate_kube_secret_def () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING KUBE SECRET DEF"
  ################################################################################
cat > ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-ssh-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${OPENSTACK_KUBE_SVC_NAME}-ssh-secret
  namespace: ${OPENSTACK_KUBE_SVC_NAMESPACE}
type: Opaque
data:
  cirt: $( cat ${KUBE_SVC_CRT_LOC} | base64 --wrap=0 )
  key: $( cat ${KUBE_SVC_KEY_LOC} | base64 --wrap=0 )
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
  ( retreive_service_cirt ) || generate_service_cirt
  generate_kube_secret_def
  kubectl_helper create -f ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-ssh-secret.yaml
  rm -rf ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-ssh-secret.yaml
  kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-ssh-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE}
}


delete_kube_secret () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DELETING SERVICE SECRET"
  ################################################################################
  get_service_cirt
  generate_kube_secret_def
  kubectl_helper delete -f ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-ssl-secret.yaml
}




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: STARTING SERVICE ENPOINT MANAGEMENT"
################################################################################
retreive_kubeconfig

#delete_kube_secret
kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-ssh-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE} || \
  create_kube_service_cirt_and_secret


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: CLEANING UP"
################################################################################
rm -rf ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/*
