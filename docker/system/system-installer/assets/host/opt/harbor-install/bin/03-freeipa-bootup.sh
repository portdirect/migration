#!/bin/bash
set -e
PATH=${PATH}:/usr/local/bin
source /etc/harbor/network.env

IPA_DATA_DIR=/var/lib/harbor/freeipa/master
docker -H unix:///var/run/docker-init-bootstrap.sock stop freeipa-master || true
docker -H unix:///var/run/docker-init-bootstrap.sock kill freeipa-master || true
docker -H unix:///var/run/docker-init-bootstrap.sock rm -v freeipa-master || true
docker -H unix:///var/run/docker-init-bootstrap.sock run -t -d \
  --hostname=freeipa-master.${OS_DOMAIN} \
  --name=freeipa-master \
  -v ${IPA_DATA_DIR}:/data:rw \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --dns=8.8.8.8 \
  -e OS_DOMAIN=harboros.net \
  docker.io/port/ipa-server:latest

FREEIPA_CMD="docker -H unix:///var/run/docker-init-bootstrap.sock exec freeipa-master"

FREEIPA_MASTER_IP=$(docker -H unix:///var/run/docker-init-bootstrap.sock inspect --format '{{ .NetworkSettings.IPAddress }}' freeipa-master)

until dig freeipa-master.${OS_DOMAIN} @${FREEIPA_MASTER_IP}
do
  echo "Waiting for FreeIPA DNS to respond"
  sleep 2
done

cat /etc/resolv.conf > /etc/resolv-orig.conf
echo "nameserver ${FREEIPA_MASTER_IP}" > /etc/resolv.conf
ping -c 1 freeipa-master.${OS_DOMAIN}
