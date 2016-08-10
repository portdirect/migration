#!/bin/bash

NODE_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
MASTER_IP=10.142.0.15
echo "${NODE_IP} $(hostname -s).novalocal $(hostname -s)" >> /etc/hosts
hostnamectl set-hostname $(hostname -s).novalocal

mkdir -p /etc/harbor
cat > /etc/harbor/kube.env <<EOF
KUBE_DEV=eth0
MASTER_IP=${MASTER_IP}
ROLE=node
EOF


systemctl restart kubelet
