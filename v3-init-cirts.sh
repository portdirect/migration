#!/bin/sh
export PATH=/usr/local/bin:${PATH}
source /etc/openstack/openstack.env
IPA_DATA_DIR=/var/lib/harbor/freeipa/master




FREEIPA_CMD="docker -H unix:///var/run/docker-init-bootstrap.sock exec freeipa-master"

FREEIPA_MASTER_IP=$(docker -H unix:///var/run/docker-init-bootstrap.sock inspect --format '{{ .NetworkSettings.IPAddress }}' freeipa-master)

until dig freeipa-master.harboros.net @${FREEIPA_MASTER_IP}
do
  echo "Waiting for FreeIPA DNS to respond"
  sleep 2
done



DOCKER_CMD="docker -H unix:///var/run/docker-init-bootstrap.sock"
IPA_ADMIN_USER=admin
IPA_ADMIN_PASSWORD=Password123


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
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER}"
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d) ${SVC_HOST_NAME} --a-rec=${SVC_HOST_IP}"
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-add ${SVC_HOST_NAME}.$(hostname -d) --desc=\"kubernetes service endpoint\" --location=\$(hostname --fqdn)"
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa host-add-managedby ${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"

 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add ${SVC_HOST_TYPE}/${SVC_HOST_NAME}.$(hostname -d)"
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa service-add-host ${SVC_HOST_TYPE}/${SVC_HOST_NAME}.$(hostname -d) --hosts=\$(hostname --fqdn)"
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} mkdir -p ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa-getcert request -r \
 -f ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt \
 -k ${SVC_AUTH_ROOT_CONTAINER}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key \
 -N CN=${SVC_HOST_NAME}.$(hostname -d) \
 -D ${SVC_HOST_NAME}.$(hostname -d) \
 -K ${SVC_HOST_TYPE}/${SVC_HOST_NAME}.$(hostname -d)"
 ${DOCKER_CMD} exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"
 sleep 30s
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




#First generate the certificate and key pair for the kubernetes api server:
generate_service_cirt etcd-kube 10.100.0.3 HTTP
generate_service_cirt etcd-network 10.100.0.4 HTTP


#And now we will generate the certificate and key pair for the kubernetes services:
generate_service_cirt etcd-docker 10.100.0.5 HTTP
generate_service_cirt docker-swarm 10.100.0.6 HTTP

sed -i "/$(hostname -f)/c\127.0.0.1 $(hostname -f) $(hostname -s)" /etc/hosts
echo "127.0.0.1 kubernetes.$(hostname -d) kubernetes" >> /etc/hosts
echo "127.0.0.1 etcd-kube.$(hostname -d) etcd-kube" >> /etc/hosts
echo "127.0.0.1 etcd-network.$(hostname -d) etcd-network" >> /etc/hosts
echo "127.0.0.1 etcd-docker.$(hostname -d) etcd-network" >> /etc/hosts
echo "127.0.0.1 docker-swarm.$(hostname -d) docker-swarm" >> /etc/hosts
