#!/bin/bash

OPENSTACK_COMPONENT=os-neutron
OPENSTACK_SUBCOMPONENT=router

source /etc/os-common/common.env
source /etc/$OPENSTACK_COMPONENT/$OPENSTACK_COMPONENT.env


ROUTER_NAME=neutron-router

EXT_IP=$(ip -f inet -o addr show $EXT_DEV|cut -d\  -f 7 | cut -d/ -f 1)
docker stop ${ROUTER_NAME}
docker rm -v ${ROUTER_NAME}
docker run -d --privileged=true --name=${ROUTER_NAME} --net=none registry.harboros.net:3040/harboros/neutron-router:latest

pipework ${NEUTRON_FLAT_NETWORK_INTERFACE} -i eth0 -l neutron_link ${ROUTER_NAME} ${NEUTRON_GATEWAY_IP}/16@${EXT_IP}
iptables -t nat -A POSTROUTING -o ${EXT_DEV} -j MASQUERADE
iptables -A FORWARD -i ${EXT_DEV} -o neutron_link -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i neutron_link -o ${EXT_DEV} -j ACCEPT



source /etc/etcd/etcd.env

ETCD_IP=$(ip -f inet -o addr show $ETCD_DEV|cut -d\  -f 7 | cut -d/ -f 1)
ETCD_NAME=$(hostname --fqdn)


source /etc/skydns/skydns.env

SKYDNS_IP=$(ip -f inet -o addr show $SKYDNS_DEV|cut -d\  -f 7 | cut -d/ -f 1)




SKYDNS_NAME=neutron-skydns
docker rm -v ${SKYDNS_NAME}
docker run -d \
    --name=${SKYDNS_NAME} \
    --net=container:${ROUTER_NAME} \
    gcr.io/google_containers/skydns:2015-03-11-001 \
        -addr=${NEUTRON_GATEWAY_IP}:53 \
        -machines="http://${ETCD_IP}:4001" \
        -nameservers="${SKYDNS_IP}:53" \
        -domain="novalocal."





OPENSTACK_COMPONENT=os-neutron
OPENSTACK_SUBCOMPONENT=router

source /etc/os-common/common.env
source /etc/$OPENSTACK_COMPONENT/$OPENSTACK_COMPONENT.env


ROUTER_NAME=neutron-router
EXT_DEV=brex0
NEUTRON_FLAT_NETWORK_INTERFACE=br1
NEUTRON_GATEWAY_IP=10.142.0.2
EXT_IP=$(ip -f inet -o addr show $EXT_DEV|cut -d\  -f 7 | cut -d/ -f 1)
docker stop ${ROUTER_NAME}
docker rm -v ${ROUTER_NAME}
docker run -d --privileged=true --name=${ROUTER_NAME} --net=none port/base tail -f /dev/null

pipework ${NEUTRON_FLAT_NETWORK_INTERFACE} -i eth0 -l neutron_link ${ROUTER_NAME} ${NEUTRON_GATEWAY_IP}/16@${EXT_IP}
iptables -t nat -A POSTROUTING -o ${EXT_DEV} -j MASQUERADE
iptables -A FORWARD -i ${EXT_DEV} -o neutron_link -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i neutron_link -o ${EXT_DEV} -j ACCEPT



source /etc/etcd/etcd.env

ETCD_IP=$(ip -f inet -o addr show $ETCD_DEV|cut -d\  -f 7 | cut -d/ -f 1)
ETCD_NAME=$(hostname --fqdn)


source /etc/skydns/skydns.env

SKYDNS_IP=$(ip -f inet -o addr show $SKYDNS_DEV|cut -d\  -f 7 | cut -d/ -f 1)




SKYDNS_NAME=neutron-skydns
docker rm -v ${SKYDNS_NAME}
docker run -d \
--name=${SKYDNS_NAME} \
--net=container:${ROUTER_NAME} \
gcr.io/google_containers/skydns:2015-03-11-001 \
-addr=${NEUTRON_GATEWAY_IP}:53 \
-machines="http://${ETCD_IP}:4001" \
-nameservers="${SKYDNS_IP}:53" \
-domain="novalocal."




#
#
# OPENSTACK_PUBLIC_DOMAIN=port.direct
# etcdctl set /neutron-skydns/config "{\"dns_addr\":\"0.0.0.0:53\",\"ttl\":3600, \"nameservers\": [\"ipa.${OPENSTACK_PUBLIC_DOMAIN}:53\"]}"
#
#
#
#
# OPENSTACK_COMPONENT=os-messaging
# OPENSTACK_COMPONENT_PUBLIC_DNS=${OPENSTACK_COMPONENT}.${OPENSTACK_PUBLIC_DOMAIN}
# OPENSTACK_COMPONENT_NAMESPACE=${OPENSTACK_COMPONENT}
# OPENSTACK_COMPONENT_SERVICE=${OPENSTACK_COMPONENT}
# SKYDNS_KEY=/neutron-skydns/local/skydns/svc/${OPENSTACK_COMPONENT_NAMESPACE}/${OPENSTACK_COMPONENT_SERVICE}
# etcdctl set ${SKYDNS_KEY} "{\"host\":\"${OPENSTACK_COMPONENT_PUBLIC_DNS}\",\"priority\":20}"
