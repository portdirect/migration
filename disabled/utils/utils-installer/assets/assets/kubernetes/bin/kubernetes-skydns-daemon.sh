#!/bin/bash

source /etc/etcd/etcd.env
source /etc/kubernetes/kubernetes.env
source /etc/kubernetes/deploy.env

KUBE_IP=$(ip -f inet -o addr show $KUBE_DEV|cut -d\  -f 7 | cut -d/ -f 1)

exec docker -H unix:///var/run/docker-bootstrap.sock run \
      --name kube2sky \
      --net='host' \
      ${KUBESKY_IMAGE} \
          -domain="${KUBE_DOMAIN}" \
          -etcd-server="http://127.0.0.1:2379" \
          -kube_master_url="http://${KUBE_IP}:${KUBE_PORT}"
