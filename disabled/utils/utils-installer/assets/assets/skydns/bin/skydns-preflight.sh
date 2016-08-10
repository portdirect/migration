#!/bin/bash

DOCKER_CMD='docker -H unix:///var/run/docker-bootstrap.sock'
ETCD_CONTAINER=etcd
ETCDCTL_COMMAND="$DOCKER_CMD exec $ETCD_CONTAINER etcdctl"

while ! echo 'HarborOS: ETCD: now up' | $ETCDCTL_COMMAND member list ; do sleep 1; done
source /etc/os-common/common.env
source /etc/skydns/skydns.env

$ETCDCTL_COMMAND set /${OS_DISTRO}/freeipa/status DOWN
UPSTREAM_DNS=$SKYDNS_UPSTREAM_DNS
$ETCDCTL_COMMAND set /skydns/config "{\"dns_addr\":\"0.0.0.0:53\",\"ttl\":3600, \"nameservers\": [\"$UPSTREAM_DNS:53\"]}"
