#!/bin/bash
set -e
PATH=${PATH}:/usr/local/bin

docker -H unix:///var/run/docker-init-bootstrap.sock stop freeipa-master || true
docker -H unix:///var/run/docker-init-bootstrap.sock kill freeipa-master || true
docker -H unix:///var/run/docker-init-bootstrap.sock rm -v freeipa-master || true

sleep 5s
kill $(cat /var/run/docker-init-bootstrap.pid)
sleep 5s
rm -rf /var/lib/docker-init-bootstrap


ip link set dev docker1 down || true
brctl delbr docker1 || true

ip link set dev docker0 down || true
brctl delbr docker0 || true
