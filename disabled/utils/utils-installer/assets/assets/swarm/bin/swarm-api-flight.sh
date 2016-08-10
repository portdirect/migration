#!/bin/bash
set -e
source /etc/swarm/swarm.env
SWARM_IP=$(ip -f inet -o addr show $SWARM_DEV|cut -d\  -f 7 | cut -d/ -f 1)

exec docker -H unix:///var/run/docker-bootstrap.sock run --net=host \
          --name swarm-api \
          --restart always \
          docker.io/swarm:latest manage \
              -H tcp://${SWARM_IP}:2376 \
              etcd://127.0.0.1:2379/dockerswarm
