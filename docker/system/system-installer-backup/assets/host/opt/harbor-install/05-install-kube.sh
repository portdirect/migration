#!/bin/sh
export PATH=/usr/local/bin:${PATH}
source /etc/openstack/openstack.env



ACTION=restart
systemctl ${ACTION} harbor-kube-bootstrap
systemctl ${ACTION} harbor-kube-apiserver
systemctl ${ACTION} harbor-kube-scheduler
systemctl ${ACTION} harbor-kube-controller-manager
systemctl ${ACTION} harbor-kube-proxy
systemctl ${ACTION} harbor-kubelet


ACTION=status
systemctl ${ACTION} harbor-kube-bootstrap
systemctl ${ACTION} harbor-kube-apiserver
systemctl ${ACTION} harbor-kube-scheduler
systemctl ${ACTION} harbor-kube-controller-manager
systemctl ${ACTION} harbor-kubelet
systemctl ${ACTION} harbor-kube-proxy


FREEIPA_CONTAINER_NAME=freeipa-master
KUBE_SVC_NAME=kubernetes
KUBE_SVC_IP=$(kubectl get svc | grep ${KUBE_SVC_NAME} | awk '{print $2}')
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER}"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-del $(hostname -d) ${KUBE_SVC_NAME} --del-all"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d) ${KUBE_SVC_NAME} --a-rec=${KUBE_SVC_IP}"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"




KUBE_SKYDNS_IP=10.112.0.4
KUBE_DNS_IP=10.112.0.2


#Now we can create our SkyDNS replication controller:

OS_DOMAIN="$(hostname -d)"
KUBE_MASTER_HOST="kubernetes.${OS_DOMAIN}"
KUBEMASTER_URL="https://${KUBE_MASTER_HOST}"





COMPONENT=freeipa-ns
harbor-docker cp kubelet:/etc/kube/harbor/${COMPONENT}.yaml /tmp/
kubectl create -f /tmp/${COMPONENT}.yaml
rm -rf /tmp/${COMPONENT}.yaml

COMPONENT=freeipa-services
harbor-docker cp kubelet:/etc/kube/harbor/${COMPONENT}.yaml /tmp/
MASTER_IP=$(ip -f inet -o addr show br0|cut -d\  -f 7 | cut -d/  -f 1)
MASTER_CONTAINER_IP=10.140.0.2
sed -i "s,{{CLUSTER_MASTER_IPA_IP}},${KUBE_DNS_IP}," /tmp/${COMPONENT}.yaml
sed -i "s,{{MASTER_IPA_IP}},${MASTER_IP}," /tmp/${COMPONENT}.yaml
sed -i "s,{{MASTER_IPA_CONTAINER_IP}},${MASTER_CONTAINER_IP}," /tmp/${COMPONENT}.yaml
kubectl create -f /tmp/${COMPONENT}.yaml
rm -rf /tmp/${COMPONENT}.yaml



COMPONENT=kube-system
harbor-docker cp kubelet:/etc/kube/addons/${COMPONENT}.yaml /tmp/
kubectl create -f /tmp/${COMPONENT}.yaml
rm -rf /tmp/${COMPONENT}.yaml

COMPONENT=dns
harbor-docker cp kubelet:/etc/kube/addons/${COMPONENT}.yaml /tmp/
sed -i "s/{{OS_DOMAIN}}/${OS_DOMAIN}/" /tmp/${COMPONENT}.yaml
sed -i "s,{{KUBEMASTER_URL}},${KUBEMASTER_URL}," /tmp/${COMPONENT}.yaml
sed -i "s/{{KUBE_SKYDNS_IP}}/${KUBE_SKYDNS_IP}/" /tmp/${COMPONENT}.yaml
sed -i "s/{{KUBE_DNS_IP}}/${KUBE_DNS_IP}/" /tmp/${COMPONENT}.yaml
kubectl delete -f /tmp/${COMPONENT}.yaml
kubectl create -f /tmp/${COMPONENT}.yaml
rm -rf /tmp/${COMPONENT}.yaml

#Once it is up and running check it is working by running:
dig -t A kube-dns.kube-system.svc.$(hostname -d). @${KUBE_SKYDNS_IP}

(
FREEIPA_CONTAINER_NAME=freeipa-master
#If the above returns your KUBE_SKYDNS_IP as an A record then SkyDNS and the Kubernetes Adapter are working, now we need to make FreeIPA use them:
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER}"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsforwardzone-add  svc.$(hostname -d). --forwarder ${KUBE_SKYDNS_IP}"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsforwardzone-add pod.$(hostname -d). --forwarder ${KUBE_SKYDNS_IP}"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d) skydns --a-rec ${KUBE_SKYDNS_IP}"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d). svc --ns-rec=skydns"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d). pod --ns-rec=skydns"
ipa-docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"
)
#Once it is up and running check it is working by running:
dig -t A kube-dns.kube-system.svc.$(hostname -d). @freeipa-master


kubectl label --overwrite node $(hostname --fqdn) freeipa=master
kubectl label --overwrite node $(hostname --fqdn) arch=x86


# the pod has started we should check to see if it is responding correctly, you should see the KUBE_SKYDNS_IP returned, but this time from the IPA server:
dig -t A kube-dns.kube-system.svc.$(hostname -d). @${KUBE_DNS_IP}
