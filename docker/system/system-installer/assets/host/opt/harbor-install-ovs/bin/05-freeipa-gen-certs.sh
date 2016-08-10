#!/bin/bash
set -e
PATH=${PATH}:/usr/local/bin
source /etc/harbor/network.env
source /etc/harbor/auth.env





DOCKER_CMD="docker -H unix:///var/run/docker-init-bootstrap.sock"



FREEIPA_MASTER_IP=$(docker -H unix:///var/run/docker-init-bootstrap.sock inspect --format '{{ .NetworkSettings.IPAddress }}' freeipa-master)

until dig freeipa-master.${OS_DOMAIN} @${FREEIPA_MASTER_IP}
do
  echo "Waiting for FreeIPA DNS to respond"
  sleep 2
done


generate_service_cirt () {
 SVC_HOST_NAME=$1
 SVC_HOST_IP=$2
 SVC_HOST_TYPE=$3

 FREEIPA_CONTAINER_NAME=freeipa-master
 SVC_AUTH_ROOT_CONTAINER=/data/harbor/auth
 SVC_AUTH_ROOT_HOST=/etc/harbor/auth
 mkdir -p ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}
 KUBE_SVC_KEY_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key
 KUBE_SVC_CRT_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt
 KUBE_SVC_CA_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER} && \
        ipa dnsrecord-add $(hostname -d) ${SVC_HOST_NAME} --a-rec=${SVC_HOST_IP} && \
        ipa host-add ${SVC_HOST_NAME}.$(hostname -d) --desc=\"Kubernetes Service Endpoint\" --location=\$(hostname --fqdn) && \
        ipa host-add-managedby ${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn) && \
        ipa service-add ${SVC_HOST_TYPE}/${SVC_HOST_NAME}.$(hostname -d) && \
        ipa service-add-host ${SVC_HOST_TYPE}/${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn) && \
        mkdir -p ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME} && \
        ipa-getcert request -r \
           -f ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt \
           -k ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key \
           -N CN=${SVC_HOST_NAME}.$(hostname -d) \
           -D ${SVC_HOST_NAME}.$(hostname -d) \
           -K ${SVC_HOST_TYPE}/${SVC_HOST_NAME}.$(hostname -d) && \
        kdestroy"
  until ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key; do
     echo "Waiting for Key"
     sleep 2
  done
  until ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} ls ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt; do
    echo "Waiting for Cert"
    sleep 2
  done
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key > ${KUBE_SVC_KEY_LOC}
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} cat ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt> ${KUBE_SVC_CRT_LOC}
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} cat /etc/ipa/ca.crt > ${KUBE_SVC_CA_LOC}
}


#First generate the certificate and key pair for the kubernetes api server:
generate_service_cirt kubernetes ${SERVICE_IP_KUBE} HTTP

#And now we will generate the certificate and key pair for the kubernetes services:
generate_service_cirt kubelet ${SERVICE_IP_KUBELET} HTTP

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
- name: $(echo $(hostname -d) | tr '.' '-')
  cluster:
    certificate-authority-data: $(cat ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt | base64 --wrap=0)
contexts:
- context:
    cluster: $(echo $(hostname -d) | tr '.' '-')
    user: kubelet
  name: service-account-context
current-context: service-account-context
EOF

# Copy the kubeconfig to the IPA server storage for use by the pxe provisioner and other services.
IPA_DATA_DIR=/var/lib/harbor/freeipa/master
cat ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/kubeconfig.yaml > $IPA_DATA_DIR/harbor/auth/kubelet/kubeconfig.yaml

#Generate the certificate and keys for the ETCD Servers:
generate_service_cirt etcd-kube ${SERVICE_IP_ETCD_KUBE} HTTP
generate_service_cirt etcd-network ${SERVICE_IP_ETCD_NETWORK} HTTP
generate_service_cirt etcd-docker ${SERVICE_IP_ETCD_DOCKER} HTTP

#Generate the certificate and keys for the Docker Swarm API:
generate_service_cirt docker-swarm ${SERVICE_IP_SWARM} HTTP

#Generate the certificate and keys for the Flocker Server:
generate_service_cirt flocker ${SERVICE_IP_FLOCKER} HTTP

echo "127.0.0.1 kubernetes.$(hostname -d) kubernetes" >> /etc/hosts
echo "127.0.0.1 etcd-kube.$(hostname -d) etcd-kube" >> /etc/hosts
echo "127.0.0.1 etcd-network.$(hostname -d) etcd-network" >> /etc/hosts
echo "127.0.0.1 etcd-docker.$(hostname -d) etcd-network" >> /etc/hosts
echo "127.0.0.1 docker-swarm.$(hostname -d) docker-swarm" >> /etc/hosts
echo "127.0.0.1 flocker.$(hostname -d) docker-swarm" >> /etc/hosts
