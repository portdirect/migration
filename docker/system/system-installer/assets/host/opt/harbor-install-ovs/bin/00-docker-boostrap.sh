#!/bin/bash
set -e
PATH=${PATH}:/usr/local/bin

touch /etc/master-node

# systemctl mask cloud-init cloud-init-local cloud-config cloud-final
# systemctl stop cloud-init cloud-init-local cloud-config cloud-final
systemctl start docker
docker pull docker.io/port/system-installer:latest
docker run \
       --privileged=true \
       -v /:/host \
       -t \
       --net=host \
       docker.io/port/system-installer:latest /init

#Reload systemd units, remove the inital docker graph directory, and make sure firewalld is not running:
systemctl stop docker
systemctl daemon-reload || true
rm -rf /var/lib/docker/
systemctl stop firewalld || true
systemctl disable firewalld || true
systemctl mask firewalld || true
systemctl stop rpcbind.service || true
systemctl disable rpcbind.service || true
systemctl mask rpcbind.service || true



mkdir -p /etc/harbor
ls /etc/harbor/network.env || cp /etc/harbor/network-default.env /etc/harbor/network.env
sed -i "s/OS_DOMAIN=local.tld/OS_DOMAIN=$(hostname -d)/g" /etc/harbor/network.env


source /etc/harbor/network.env

ip link set dev docker1 down || true
brctl delbr docker1 || true
brctl addbr docker1 || true
ip addr add ${FLANNEL_WAN_NETWORK} dev docker1 || true
ip link set dev docker1 mtu 1500 || true
ip link set dev docker1 up || true

HOST_DOCKER_IP=$(ip -f inet -o addr show docker1|cut -d\  -f 7 | cut -d/ -f 1)
echo "$HOST_DOCKER_IP $(hostname -s).$(hostname -d) $(hostname -s)" >> /etc/hosts

/usr/bin/docker-current daemon \
        --exec-opt native.cgroupdriver=systemd \
        -H unix:///var/run/docker-init-bootstrap.sock \
        -p /var/run/docker-init-bootstrap.pid \
        --graph=/var/lib/docker-init-bootstrap \
        --bridge=docker1 \
        --dns="${EXTERNAL_DNS}" \
        --mtu=1500 \
        --fixed-cidr=${FLANNEL_WAN_NETWORK} \
        --ip=${HOST_DOCKER_IP} \
        --userland-proxy=false \
        --storage-driver overlay &

sleep 20s
sed -i 's/%wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tNOPASSWD: ALL/g' /etc/sudoers
chmod +x /opt/harbor-install/bin/*
/opt/harbor-install/bin/gen-passwords.sh
/opt/harbor-install/bin/01-freeipa-envgen.sh
/opt/harbor-install/bin/02-freeipa-bootstrap.sh
/opt/harbor-install/bin/03-freeipa-bootup.sh
/opt/harbor-install/bin/04-freeipa-host-enroll.sh
/opt/harbor-install/bin/05-freeipa-gen-certs.sh
/opt/harbor-install/bin/06-cleanup.sh
