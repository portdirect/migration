#!/bin/bash

#ETCD

MODULE=ovs

mkdir -p ${SYS_ROOT}/etc/${MODULE}/
cp -r ./assets/${MODULE}/etc/* ${SYS_ROOT}/etc/${MODULE}/

mkdir -p ${SYS_ROOT}/var/usrlocal/bin/
chmod +x ./assets/${MODULE}/bin/*
cp -r ./assets/${MODULE}/bin/* ${SYS_ROOT}/var/usrlocal/bin/

cp ./assets/${MODULE}/*.service ${SYS_ROOT}/etc/systemd/system/
cp ./assets/${MODULE}/*.path ${SYS_ROOT}/etc/systemd/system/
