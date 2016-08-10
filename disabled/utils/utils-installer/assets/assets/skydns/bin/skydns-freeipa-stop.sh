#!/bin/bash

source /etc/os-common/common.env
source /etc/skydns/skydns.env

DOCKER_CMD='docker -H unix:///var/run/docker-bootstrap.sock'
ETCD_CONTAINER=etcd
ETCDCTL_COMMAND_COMMAND="$DOCKER_CMD exec $ETCD_CONTAINER etcdctl"

$ETCDCTL_COMMAND set /skydns/config "{\"dns_addr\":\"0.0.0.0:53\",\"ttl\":3600, \"nameservers\": [\"$UPSTREAM_DNS:53\"]}"
systemctl restart skydns.service
