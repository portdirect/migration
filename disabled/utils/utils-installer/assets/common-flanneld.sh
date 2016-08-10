#!/bin/bash

#ETCD

MODULE=flanneld

mkdir -p ${SYS_ROOT}/etc/${MODULE}/
cp -r ./assets/${MODULE}/etc/* ${SYS_ROOT}/etc/${MODULE}/

mkdir -p ${SYS_ROOT}/var/usrlocal/bin/
chmod +x ./assets/${MODULE}/bin/*
cp -r ./assets/${MODULE}/bin/* ${SYS_ROOT}/var/usrlocal/bin/

cp ./assets/${MODULE}/*.service ${SYS_ROOT}/etc/systemd/system/
cp ./assets/${MODULE}/*.path ${SYS_ROOT}/etc/systemd/system/

mkdir -p ${SYS_ROOT}/etc/systemd/system/docker.service.d
cp ./assets/${MODULE}/docker.service.d/10-flanneld-network.conf ${SYS_ROOT}/etc/systemd/system/docker.service.d/10-flanneld-network.conf
