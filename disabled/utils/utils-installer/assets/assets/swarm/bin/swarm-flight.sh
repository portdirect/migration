#!/bin/bash
set -e
source /etc/docker/docker.env
DOCKER_IP=$(ip -f inet -o addr show $DOCKER_DEV|cut -d\  -f 7 | cut -d/ -f 1)

exec docker -H unix:///var/run/docker-bootstrap.sock run --net=host \
          --name swarm \
          --restart always \
          docker.io/swarm:latest join \
              --addr=${DOCKER_IP}:2375 \
              etcd://127.0.0.1:2379/dockerswarm
