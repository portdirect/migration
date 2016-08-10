#!/bin/sh







export PATH=/usr/local/bin:$PATH
systemctl daemon-reload
systemctl restart docker-bootstrap
systemctl enable docker-bootstrap
docker-bootstrap info


systemctl daemon-reload
systemctl restart skydns
systemctl enable skydns
HOST_DOCKER_LOCAL_IP=$(ip -f inet -o addr show docker|cut -d\  -f 7 | cut -d/ -f 1)
dig @${HOST_DOCKER_LOCAL_IP}

# systemctl daemon-reload
# systemctl restart openvswitch
# systemctl enable openvswitch
# ovs-vsctl show



systemctl daemon-reload
systemctl restart flannel
systemctl enable flannel
ip addr show flannel.1


calicoctl pool add 192.168.0.0/16 --nat-outgoing --ipip


systemctl daemon-reload
systemctl restart docker-wan
systemctl enable docker-wan
docker-wan info



systemctl daemon-reload
systemctl restart freeipa-master
systemctl enable freeipa-master
docker-wan logs freeipa-master
source /etc/harbor/auth.env
docker-wan exec -it freeipa-master /usr/bin/secure-ldap ${IPA_DS_PASSWORD}
docker-wan exec -it freeipa-master systemctl restart dirsrv.target


systemctl daemon-reload
systemctl restart docker
systemctl enable docker
docker info


systemctl daemon-reload
systemctl restart kubelet
systemctl enable kubelet

systemctl restart docker
systemctl restart kubelet


(
kubectl label --overwrite node $(hostname --fqdn) arch=x86
kubectl label --overwrite node $(hostname --fqdn) freeipa=master
kubectl label --overwrite node $(hostname --fqdn) cockpit='true'
kubectl label --overwrite node $(hostname --fqdn) kube-dns='true'
)
FREEIPA_MASTER_IP=$(docker-wan inspect --format '{{ .NetworkSettings.IPAddress }}' freeipa-master)

sed -i "s/10.98.60.2/${FREEIPA_MASTER_IP}/g" /etc/kubernetes/applications/freeipa.yaml


for namespace in $(ls /etc/kubernetes/namespaces)
do
 echo "Creating namespace $namespace"
 kubectl create -f /rootfs/etc/kubernetes/namespaces/$namespace
done


for application in $(ls /etc/kubernetes/applications)
do
 echo "Creating spplication $application"
 sed -i "s/{{OS_DOMAIN}}/$(hostname -d)/g" /etc/kubernetes/applications/$application
 kubectl delete -f /rootfs/etc/kubernetes/applications/$application || true
 kubectl create -f /rootfs/etc/kubernetes/applications/$application
done
)


systemctl daemon-reload
systemctl restart calico
systemctl enable calico
# This may fail untill calico is fully running


systemctl daemon-reload
systemctl restart docker-swarm
systemctl enable docker-swarm


systemctl daemon-reload
systemctl restart docker-swarm-manager
systemctl enable docker-swarm-manager
docker-swarm info







systemctl restart kubelet




#Once it is up and running check it is working by running:
dig +short -t A kube-dns.kube-system.svc.$(hostname -d). @10.100.0.7
#If the above returns your KUBE_SKYDNS_IP as an A record then SkyDNS and the Kubernetes Adapter are working, now we need to make FreeIPA use them:
FREEIPA_CONTAINER_NAME=freeipa-master
source /etc/harbor/auth.env
docker-wan exec ${FREEIPA_CONTAINER_NAME} /bin/bash \
-c "echo ${IPA_ADMIN_PASSWORD} | kinit ${IPA_ADMIN_USER} && \
    ipa dnsforwardzone-add svc.$(hostname -d). --forwarder 10.100.0.7 && \
    ipa dnsforwardzone-add pod.$(hostname -d). --forwarder 10.100.0.7 && \
    ipa dnsrecord-add $(hostname -d) skydns --a-rec 10.100.0.7 && \
    sleep 5s && \
    ipa dnsrecord-add $(hostname -d). svc --ns-rec=skydns && \
    ipa dnsrecord-add $(hostname -d). pod --ns-rec=skydns && \
    kdestroy"


#Once it is up and running check it is working by running:
dig +short -t A kube-dns.kube-system.svc.$(hostname -d). @freeipa-master
