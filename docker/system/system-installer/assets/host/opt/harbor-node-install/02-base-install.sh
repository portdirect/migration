#!/bin/sh


















export PATH=/usr/local/bin:$PATH
systemctl daemon-reload
systemctl restart docker-bootstrap
systemctl enable docker-bootstrap
docker-bootstrap info



systemctl daemon-reload
systemctl restart flannel
systemctl enable flannel
ip addr show flannel.1

systemctl daemon-reload
systemctl restart skydns
systemctl status skydns
systemctl enable skydns
HOST_DOCKER_LOCAL_IP=$(ip -f inet -o addr show docker|cut -d\  -f 7 | cut -d/ -f 1)
dig skydns.local @${HOST_DOCKER_LOCAL_IP}

# systemctl daemon-reload
# systemctl restart openvswitch
# systemctl enable openvswitch
# ovs-vsctl show






systemctl daemon-reload
systemctl restart docker-wan
systemctl enable docker-wan
docker-wan info


systemctl daemon-reload
systemctl restart docker
systemctl enable docker
docker info

mv /etc/kubernetes/manifests /etc/kubernetes/manifests-master
mkdir -p /etc/kubernetes/manifests
cp /etc/kubernetes/manifests-master/kube-proxy.manifest /etc/kubernetes/manifests/

systemctl daemon-reload
systemctl restart kubelet
systemctl enable kubelet

systemctl restart docker
systemctl restart kubelet


systemctl daemon-reload
systemctl restart calico
systemctl enable calico
# This may fail untill calico is fully running


systemctl daemon-reload
systemctl restart docker-swarm
systemctl enable docker-swarm
