#!/bin/bash
set -e
docker-bootstrap pull docker.io/port/system-installer:latest
docker-bootstrap run \
       --privileged=true \
       -v /:/host \
       -t \
       --rm \
       --net=host \
       docker.io/port/system-installer:latest /init
