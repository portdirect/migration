#!/bin/bash

OPENSTACK_COMPONENT=pxe
OPENSTACK_SUBCOMPONENT=server

source /etc/os-common/common.env
source /etc/freeipa/credentials-client-provisioning.env
source /etc/$OPENSTACK_COMPONENT/$OPENSTACK_COMPONENT.env



source /etc/etcd/etcd.env
source /etc/docker/docker.env
source /etc/flanneld/flanneld.env
source /etc/skydns/skydns.env
source /etc/kubernetes/kubernetes.env
source /etc/kubernetes/deploy.env

EXT_DEV=brex0

ETCD_IP=$(ip -f inet -o addr show $ETCD_DEV|cut -d\  -f 7 | cut -d/ -f 1)
DOCKER_IP=$(ip -f inet -o addr show $DOCKER_DEV|cut -d\  -f 7 | cut -d/ -f 1)
SKYDNS_IP=$(ip -f inet -o addr show $DOCKER_DEV|cut -d\  -f 7 | cut -d/ -f 1)
KUBE_IP=$(ip -f inet -o addr show $KUBE_DEV|cut -d\  -f 7 | cut -d/ -f 1)
EXT_IP=$(ip -f inet -o addr show $EXT_DEV|cut -d\  -f 7 | cut -d/ -f 1)


echo "ETCD_IP=$ETCD_IP" > /etc/pxe/pxe-run.env
echo "DOCKER_IP=$DOCKER_IP" >> /etc/pxe/pxe-run.env
echo "SKYDNS_IP=$SKYDNS_IP" >> /etc/pxe/pxe-run.env
echo "KUBE_API_HOST=$KUBE_IP" >> /etc/pxe/pxe-run.env

/bin/docker-compose -f /etc/pxe/pxe.yaml up -d

pipework ${PXE_DEV} -i eth0 -l pxe_link pxe_server_1 ${PXE_IP}/16@${EXT_IP}
iptables -t nat -A POSTROUTING -o ${EXT_DEV} -j MASQUERADE
iptables -A FORWARD -i ${EXT_DEV} -o pxe_link -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i pxe_link -o ${EXT_DEV} -j ACCEPT
