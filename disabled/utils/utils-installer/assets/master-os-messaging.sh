#!/bin/bash

MODULE=os-messaging

mkdir -p /etc/${MODULE}/
rm -rf /etc/${MODULE}/*
cp -r ./assets/${MODULE}/etc/* /etc/${MODULE}/

mkdir -p /var/usrlocal/bin/
chmod +x ./assets/${MODULE}/bin/*
cp -r ./assets/${MODULE}/bin/* /var/usrlocal/bin/

cp ./assets/${MODULE}/*.service /etc/systemd/system/
