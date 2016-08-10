#!/bin/sh
export PATH=/usr/local/bin:${PATH}
source /etc/openstack/openstack.env

MASTER_IP=$(ip -f inet -o addr show docker0|cut -d\  -f 7 | cut -d/  -f 1)


generate_service_cirt () {
 SVC_HOST_NAME=$1
 SVC_HOST_IP=$2

 FREEIPA_CONTAINER_NAME=freeipa-master
 SVC_AUTH_ROOT_CONTAINER=/data/harbor/auth
 SVC_AUTH_ROOT_HOST=/etc/harbor/auth
 mkdir -p ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}
 KUBE_SVC_KEY_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key
 KUBE_SVC_CRT_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt
 KUBE_SVC_CA_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER}"
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d) ${SVC_HOST_NAME} --a-rec=${SVC_HOST_IP}"
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-add ${SVC_HOST_NAME}.$(hostname -d) --desc=\"kubernetes service endpoint\" --location=\$(hostname --fqdn)"
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-add-managedby ${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"

 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add HTTP/${SVC_HOST_NAME}.$(hostname -d)"
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add-host HTTP/${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"
 docker exec ${FREEIPA_CONTAINER_NAME} mkdir -p ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa-getcert request -r \
 -f ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt \
 -k ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key \
 -N CN=${SVC_HOST_NAME}.$(hostname -d) \
 -D ${SVC_HOST_NAME}.$(hostname -d) \
 -K HTTP/${SVC_HOST_NAME}.$(hostname -d)"
 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"
 sleep 30s
 docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key > ${KUBE_SVC_KEY_LOC}
 docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt> ${KUBE_SVC_CRT_LOC}
 docker exec ${FREEIPA_CONTAINER_NAME} cat /etc/ipa/ca.crt > ${KUBE_SVC_CA_LOC}
}


#First generate the certificate and key pair for the kubernetes api server:
generate_service_cirt kubernetes ${MASTER_IP}

#And now we will generate the certificate and key pair for the kubernetes services:
generate_service_cirt kubelet ${MASTER_IP}

#From the certificates we have generated, we can produce a kubeconfig file that kubernetes components will use to authenticate against the api server:
SVC_HOST_NAME=kubelet
FREEIPA_CONTAINER_NAME=freeipa-master
SVC_AUTH_ROOT_HOST=/etc/harbor/auth
cat > ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
users:
- name: kubelet
  user:
    client-certificate-data: $( cat ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt | base64 --wrap=0)
    client-key-data: $( cat ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key | base64 --wrap=0)
clusters:
- name: $(echo $OS_DOMAIN | tr '.' '-')
  cluster:
    certificate-authority-data: $(cat ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt | base64 --wrap=0)
contexts:
- context:
    cluster: $(echo $OS_DOMAIN | tr '.' '-')
    user: kubelet
  name: service-account-context
current-context: service-account-context
EOF

# Copy the kubeconfig to the IPA server storage for use by the pxe provisioner and other services.

IPA_DATA_DIR=/var/lib/harbor/freeipa-master
cp -f ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/kubeconfig.yaml $IPA_DATA_DIR/harbor/auth/kubelet/kubeconfig.yaml


#Finally we set the hosts file on the master server to resolve kubernetes to the approriate ip:
source /etc/openstack/openstack.env
MASTER_IP=$(ip -f inet -o addr show docker0|cut -d\  -f 7 | cut -d/  -f 1)
echo "${MASTER_IP} kubernetes.$(hostname -d) kubernetes" >> /etc/hosts





ipa-client-install \
 --hostname=$(hostname -s).$(hostname -d) \
 --ip-address=${MASTER_IP} \
 --no-ntp \
 --force-join \
 --unattended \
 --principal="admin" \
 --password="${IPA_ADMIN_PASSWORD}"








 generate_host_cirt () {
  SVC_HOST_NAME=$1
  FREEIPA_CONTAINER_NAME=freeipa-master
  SVC_AUTH_ROOT_CONTAINER=/data/harbor/auth
  SVC_AUTH_ROOT_HOST=/etc/harbor/auth
  mkdir -p ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}
  HOST_SVC_KEY_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key
  HOST_SVC_CRT_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt
  HOST_SVC_CA_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER}"
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add HTTP/${SVC_HOST_NAME}.$(hostname -d)"
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add-host HTTP/${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"
  docker exec ${FREEIPA_CONTAINER_NAME} mkdir -p ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa-getcert request -r \
  -f ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt \
  -k ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key \
  -N CN=${SVC_HOST_NAME}.$(hostname -d) \
  -D ${SVC_HOST_NAME}.$(hostname -d) \
  -K HTTP/${SVC_HOST_NAME}.$(hostname -d)"
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"
  sleep 30s
  docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key > ${HOST_SVC_KEY_LOC}
  docker exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt> ${HOST_SVC_CRT_LOC}
  docker exec ${FREEIPA_CONTAINER_NAME} cat /etc/ipa/ca.crt > ${HOST_SVC_CA_LOC}

  mkdir -p ${SVC_AUTH_ROOT_HOST}/host/messaging
  ln ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging.key
  ln ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging.crt
  ln ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging-ca.crt

  mkdir -p ${SVC_AUTH_ROOT_HOST}/host/database
  ln ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key ${SVC_AUTH_ROOT_HOST}/host/database/database.key
  ln ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt ${SVC_AUTH_ROOT_HOST}/host/database/database.crt
  ln ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt ${SVC_AUTH_ROOT_HOST}/host/database/database-ca.crt

 }

 generate_host_cirt $(hostname -s)
