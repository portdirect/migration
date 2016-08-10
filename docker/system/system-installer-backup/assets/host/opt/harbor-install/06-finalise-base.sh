#!/bin/sh
source /etc/openstack/openstack.env
export PATH=/usr/local/bin:${PATH}


COMPONENT=cockpit-ns
harbor-docker cp kubelet:/etc/kube/harbor/${COMPONENT}.yaml /tmp/
kubectl create -f /tmp/${COMPONENT}.yaml
rm -rf /tmp/${COMPONENT}.yaml

COMPONENT=cockpit
harbor-docker cp kubelet:/etc/kube/harbor/${COMPONENT}.yaml /tmp/
kubectl delete -f /tmp/${COMPONENT}.yaml
kubectl create -f /tmp/${COMPONENT}.yaml
rm -rf /tmp/${COMPONENT}.yaml

kubectl label --overwrite node $(hostname --fqdn) cockpit=true
#Finally lets reboot the host to make sure that everything comes up smoothly:

ACTION=enable
systemctl ${ACTION} docker-bootstrap
systemctl ${ACTION} harbor-network-bootstrap
systemctl ${ACTION} harbor-ovs
systemctl ${ACTION} harbor-etcd-bootstrap
systemctl ${ACTION} harbor-etcd-master
systemctl ${ACTION} harbor-network-ovs
systemctl ${ACTION} harbor-skydns
systemctl ${ACTION} docker
systemctl ${ACTION} harbor-freeipa
systemctl ${ACTION} harbor-kube-bootstrap
systemctl ${ACTION} harbor-kube-apiserver
systemctl ${ACTION} harbor-kube-scheduler
systemctl ${ACTION} harbor-kube-controller-manager
systemctl ${ACTION} harbor-kubelet
systemctl ${ACTION} harbor-kube-proxy
systemctl ${ACTION} harbor-discs-bootstrap
systemctl ${ACTION} puppet-master

reboot
