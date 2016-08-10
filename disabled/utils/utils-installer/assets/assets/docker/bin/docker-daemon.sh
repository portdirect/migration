#!/bin/bash
set -e

source /etc/etcd/etcd.env
source /etc/docker/docker.env
source /etc/skydns/skydns.env

DOCKER_IP=$(ip -f inet -o addr show $DOCKER_DEV|cut -d\  -f 7 | cut -d/ -f 1)
SKYDNS_IP=$(ip -f inet -o addr show $SKYDNS_DEV|cut -d\  -f 7 | cut -d/ -f 1)

HOST_DOCKER_SUBNET=$(etcdctl get /ovs/network/nodes/$HOSTNAME)

exec docker daemon \
        --log-driver=json-file \
        --bridge=docker0 \
        --mtu=1462 \
        --fixed-cidr=${HOST_DOCKER_SUBNET} \
        --dns ${SKYDNS_IP} \
        -H unix:///var/run/docker.sock \
        -H tcp://${DOCKER_IP}:2375 \
        --cluster-store=etcd://127.0.0.1:2379 \
        --cluster-advertise=${DOCKER_IP}:2375 \
        --storage-driver overlay $INSECURE_REGISTRY
