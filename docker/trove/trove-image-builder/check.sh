#!/bin/bash

RES=0

. /openrc
if ! keystone token-get > /dev/null; then
    echo "ERROR: keystone token-get failed" >&2
    RES=1
else
    if ! heat stack-list > /dev/null; then
        echo "ERROR: heat stack-list failed" >&2
        RES=1
    fi
fi

exit $RES


docker run -it --rm \
--volume /run:/run \
--volume /sys/fs/cgroup:/sys/fs/cgroup \
--volume /lib/modules:/lib/modules:ro \
--volume /dev:/dev \
--volume /bin/docker:/bin/docker \
--privileged \
--net 'host' \
port/trove-server-builder:latest bash
