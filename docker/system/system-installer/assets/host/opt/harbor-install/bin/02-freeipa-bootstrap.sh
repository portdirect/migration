#!/bin/bash
set -e
PATH=${PATH}:/usr/local/bin
source /etc/harbor/network.env

IPA_DATA_DIR=/var/lib/harbor/freeipa/master
docker -H unix:///var/run/docker-init-bootstrap.sock stop freeipa-master || true
docker -H unix:///var/run/docker-init-bootstrap.sock kill freeipa-master || true
docker -H unix:///var/run/docker-init-bootstrap.sock rm -v freeipa-master || true
docker -H unix:///var/run/docker-init-bootstrap.sock run -t \
    --hostname=freeipa-master.${OS_DOMAIN} \
    --name=freeipa-master \
    -v ${IPA_DATA_DIR}:/data:rw \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --dns=${EXTERNAL_DNS} \
    -e OS_DOMAIN=${OS_DOMAIN} \
    docker.io/port/ipa-server:latest exit-on-finished
