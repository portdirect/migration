#!/bin/bash
set -e
PATH=${PATH}:/usr/local/bin

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
systemctl daemon-reload
systemctl stop docker
rm -rf /var/lib/docker/
systemctl stop firewalld
systemctl disable firewalld
systemctl mask firewalld
systemctl mask rpcbind.service
