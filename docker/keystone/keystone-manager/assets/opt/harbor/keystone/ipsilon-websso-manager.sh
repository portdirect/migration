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
  mkdir -p /etc/httpd/saml2/websso
  if docker exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.key ; then
     docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.key > ${KUBE_SVC_KEY_LOC}
  else
      echo "Command failed"
      return 1
  fi
  if docker exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.crt ; then
     docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.crt> ${KUBE_SVC_CRT_LOC}
  else
      echo "Command failed"
      return 1
  fi
  if docker exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.xml ; then
     docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.xml > ${KUBE_SVC_CA_LOC}
  else
      echo "Command failed"
      return 1
  fi
}





generate_service_cirt () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: GENERATING SERVICE CIRT"
  ################################################################################

mkdir -p /etc/httpd/mellon
echo -n "${IPA_HOST_ADMIN_USER}" > /etc/httpd/mellon/idp_username.txt
echo -n "$IPA_HOST_ADMIN_PASSWORD" > /etc/httpd/mellon/idp_password.txt

curl --cacert /etc/ipa/ca.crt \
     --data-urlencode login_name@/etc/httpd/mellon/idp_username.txt \
     --data-urlencode login_password@/etc/httpd/mellon/idp_password.txt \
     -b /etc/httpd/mellon/cookies -c /etc/httpd/mellon/cookies \
     https://ipsilon.${OS_DOMAIN}/idp/login/form

curl -b /etc/httpd/mellon/cookies \
    -c /etc/httpd/mellon/cookies \
    --fail \
    https://ipsilon.${OS_DOMAIN}/idp/admin/providers/saml2/admin/sp/keystone/delete || true

curl -b /etc/httpd/mellon/cookies \
     -c /etc/httpd/mellon/cookies \
     --fail \
     https://ipsilon.${OS_DOMAIN}/idp/admin/providers/saml2/admin/sp/keystone || ( \

    mkdir -p /etc/httpd/mellon


    cd /etc/httpd/mellon
    ipsilon-client-install --uninstall || true
    echo ${IPA_HOST_ADMIN_PASSWORD} | ipsilon-client-install --debug \
    --hostname keystone.${OS_DOMAIN} \
    --admin-user $IPA_HOST_ADMIN_USER \
    --admin-password - \
    --saml-no-httpd \
    --saml-idp-url https://ipsilon.${OS_DOMAIN}/idp \
    --saml-auth "/federation" \
    --saml-sp "/v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon" \
    --saml-sp-logout "/v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon/logout" \
    --saml-sp-post "/v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon/postResponse" \
    --saml-sp-paos "/v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon/paosResponse" \
    --saml-sp-name "keystone" \
    --saml-sp-description "${OS_DOMAIN}: Keystone" \
    --debug
    cat /etc/httpd/mellon/certificate.pem > /etc/httpd/mellon/https_keystone.${OS_DOMAIN}_keystone.cert
    cat /etc/httpd/mellon/certificate.key > /etc/httpd/mellon/https_keystone.${OS_DOMAIN}_keystone.key
    cat /etc/httpd/mellon/metadata.xml > /etc/httpd/mellon/https_keystone.${OS_DOMAIN}_keystone.xml
    curl -L https://ipsilon.${OS_DOMAIN}/idp/saml2/metadata > /etc/httpd/mellon/idp-metadata.xml

)
rm -f /etc/httpd/mellon/idp_username.txt /etc/httpd/mellon/idp_password.txt /etc/httpd/mellon/cookies
mkdir -p /etc/httpd/saml2/websso

docker exec ${FREEIPA_CONTAINER_NAME} mkdir -p ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}
cat /etc/httpd/mellon/https_keystone.${OS_DOMAIN}_keystone.cert |docker exec -i ${FREEIPA_CONTAINER_NAME} /bin/bash -c "cat > ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.crt"
cat /etc/httpd/mellon/https_keystone.${OS_DOMAIN}_keystone.key |docker exec -i ${FREEIPA_CONTAINER_NAME} /bin/bash -c "cat > ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.key"
cat /etc/httpd/mellon/https_keystone.${OS_DOMAIN}_keystone.xml |docker exec -i ${FREEIPA_CONTAINER_NAME} /bin/bash -c "cat > ${SVC_AUTH_ROOT_IPA_CONTAINER}/${OPENSTACK_KUBE_SVC_NAME}/${OPENSTACK_KUBE_SVC_NAME}.saml.xml"




  # echo "${IPA_HOST_ADMIN_PASSWORD}" | kinit "${IPA_HOST_ADMIN_USER}"
  # mkdir -p /etc/httpd/saml2/websso
  # cd  /etc/httpd/saml2/websso && (
  # echo "${IPA_HOST_ADMIN_PASSWORD}" | ipsilon-client-install \
  # --hostname keystone.${OS_DOMAIN} \
  # --port 443 \
  # --admin-user ${IPA_HOST_ADMIN_USER} \
  # --admin-password - \
  # --saml \
  # --saml-idp-url https://ipsilon.${OS_DOMAIN}/idp \
  # --saml-idp-metadata https://ipsilon.${OS_DOMAIN}/idp/saml2/metadata \
  # --saml-no-httpd  \
  # --saml-base /v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon \
  # --saml-auth /v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon \
  # --saml-sp /v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon \
  # --saml-sp-logout /v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon/logout \
  # --saml-sp-post /v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon/postResponse \
  # --saml-sp-paos /v3/OS-FEDERATION/identity_providers/ipsilon/protocols/saml2/auth/mellon/paosResponse \
  # --saml-secure-setup  \
  # --saml-sp-name ipsilon \
  # --saml-sp-description "primary auth for keystone" \
  # --saml-sp-visible \
  # --debug
  # )
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
(kubectl_helper describe secret/${OPENSTACK_KUBE_SVC_NAME}-websso-secret --namespace=${OPENSTACK_KUBE_SVC_NAMESPACE} ) || \
  create_kube_service_cirt_and_secret
