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
OPENSTACK_KUBE_SVC_NAME="glusterfs"
OPENSTACK_KUBE_SVC_NAMESPACE="os-${OPENSTACK_KUBE_SVC_NAME}"
OPENSTACK_KUBE_SVC_IP="$(dig +short os-${OPENSTACK_KUBE_SVC_NAME}.${OPENSTACK_KUBE_SVC_NAMESPACE}.svc.${OS_DOMAIN})"
if [ -z "$OPENSTACK_KUBE_SVC_IP" ]; then
  OPENSTACK_KUBE_SVC_IP="127.0.0.1"
fi

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
KUBE_SVC_KEY_LOC=${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.key
KUBE_SVC_CRT_LOC=${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.crt
KUBE_SVC_CA_LOC=${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/ca.crt


retreive_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RETREVING SERVICE CIRT"
  ################################################################################

  if docker exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.key ; then
     docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.key > ${KUBE_SVC_KEY_LOC}
  else
      echo "Command failed"
      return 1
  fi
  if docker exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.crt ; then
     docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.crt> ${KUBE_SVC_CRT_LOC}
  else
      echo "Command failed"
      return 1
  fi
  if docker exec ${FREEIPA_CONTAINER_NAME} ls /etc/ipa/ca.crt ; then
     docker exec ${FREEIPA_CONTAINER_NAME} cat /etc/ipa/ca.crt > ${KUBE_SVC_CA_LOC}
  else
      echo "Command failed"
      return 1
  fi
}


generate_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING SERVICE CIRT"
  ################################################################################
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo \"${IPA_USER_ADMIN_PASSWORD}\" | kinit $IPA_USER_ADMIN_USER"

 # Add all services to IPA not in kubernetes
 for IP in $OPENSTACK_KUBE_SVC_IP; do
   docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-show $(hostname -d) ${OPENSTACK_KUBE_SVC_NAME} --raw" | grep "arecord" | grep -q "${IP}" || \
   docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d) ${OPENSTACK_KUBE_SVC_NAME} --a-rec=${IP}"
 done

 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-show ${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d)" || \
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-add ${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d) --desc=\"kubernetes service endpoint\" --location=\$(hostname --fqdn)" && \
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-add-managedby ${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"

 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add HTTP/${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d)"
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add-host HTTP/${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"
 docker exec ${FREEIPA_CONTAINER_NAME} mkdir -p ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa-getcert request -r \
 -f ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.crt \
 -k ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.key \
 -N CN=${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d) \
 -D ${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d) \
 -K HTTP/${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d)"
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"
 sleep 30s
 retreive_service_cirt
}



generate_kube_secret_def () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING KUBE SECRET DEF"
  ################################################################################
cat > ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-ssl-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${OPENSTACK_KUBE_SVC_NAME}-ssl-secret
  namespace: ${OPENSTACK_KUBE_SVC_NAMESPACE}
type: Opaque
data:
  host: $( echo "${OPENSTACK_KUBE_SVC_NAME}.$(hostname -d)" | base64 --wrap=0 )
  ca: $( cat ${KUBE_SVC_CA_LOC} | base64 --wrap=0 )
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
  retreive_service_cirt || generate_service_cirt
  generate_kube_secret_def
  kubectl_helper create -f ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-ssl-secret.yaml
  rm -rf ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-ssl-secret.yaml
  kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-ssl-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE}
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
kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-ssl-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE} || \
  create_kube_service_cirt_and_secret


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: CLEANING UP"
################################################################################
rm -rf ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/*
