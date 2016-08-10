#!/bin/bash
set -e
OPENSTACK_COMPONENT="IPSILON-ENDPOINT_MANAGER"
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
OPENSTACK_KUBE_SVC_NAME="keystone"
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
mkdir -p ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ENV VARS"
################################################################################
KUBE_SVC_KEY_LOC=/etc/httpd/saml2/websso/certificate.key
KUBE_SVC_CRT_LOC=/etc/httpd/saml2/websso/certificate.pem
KUBE_SVC_CA_LOC=/etc/httpd/saml2/websso/metadata.xml






retreive_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: RETREVING SERVICE CIRT"
  ################################################################################

  if ls ${KUBE_SVC_KEY_LOC} ; then
     echo "${KUBE_SVC_KEY_LOC} exists"
  else
      echo "Command failed"
      return 1
  fi
  if ls ${KUBE_SVC_CRT_LOC} ; then
     echo "${KUBE_SVC_CRT_LOC} exists"
  else
      echo "Command failed"
      return 1
  fi
  if ls ${KUBE_SVC_CA_LOC} ; then
     echo "${KUBE_SVC_CA_LOC} exists"
  else
      echo "Command failed"
      return 1
  fi
}


generate_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING SERVICE CIRT"
  ################################################################################
  echo "${IPA_HOST_ADMIN_PASSWORD}" | kinit "${IPA_HOST_ADMIN_USER}"
  mkdir -p /etc/httpd/saml2/websso
  cd  /etc/httpd/saml2/websso && (
  echo "${IPA_HOST_ADMIN_PASSWORD}" | ipsilon-client-install \
      --hostname ${KEYSTONE_PUBLIC_SERVICE_HOST} \
      --saml \
      --saml-no-httpd \
      --saml-base /v3/auth/OS-FEDERATION/websso/saml2 \
      --saml-sp /v3/auth/OS-FEDERATION/websso/saml2 \
      --saml-idp-url https://ipsilon.${OS_DOMAIN}/idp \
      --saml-sp-logout /v3/auth/OS-FEDERATION/websso/saml2/logout \
      --saml-sp-post /v3/auth/OS-FEDERATION/websso/saml2/postResponse \
      --saml-sp-name keystone \
      --saml-auth /v3/auth/OS-FEDERATION/websso/saml2 \
      --admin-user ${IPA_HOST_ADMIN_USER} \
      --admin-password -
  )
}




get_service_cirt () {
  ( retreive_service_cirt ) || ( generate_service_cirt &&  retreive_service_cirt )
}


generate_kube_secret_def () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING KUBE SECRET DEF"
  ################################################################################
cat > ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-websso-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${OPENSTACK_KUBE_SVC_NAME}-websso-secret
  namespace: ${OPENSTACK_KUBE_SVC_NAMESPACE}
type: Opaque
data:
  metadata: $( cat ${KUBE_SVC_CA_LOC} | base64 --wrap=0 )
  pem: $( cat ${KUBE_SVC_CRT_LOC} | base64 --wrap=0 )
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
  get_service_cirt
  generate_kube_secret_def
  kubectl_helper create -f ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-websso-secret.yaml
  rm -rf ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-websso-secret.yaml
  kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-websso-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE}
}


delete_kube_secret () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DELETING SERVICE SECRET"
  ################################################################################
  get_service_cirt
  generate_kube_secret_def
  kubectl_helper delete -f ${SVC_AUTH_ROOT_LOCAL_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}-websso-secret.yaml
}




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: STARTING SERVICE ENPOINT MANAGEMENT"
################################################################################
retreive_kubeconfig

#delete_kube_secret
(kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-websso-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE} && retreive_service_cirt ) || \
  create_kube_service_cirt_and_secret
