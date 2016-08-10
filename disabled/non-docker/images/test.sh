#!/bin/bash

echo "HarborOS: Importing: Cirros Image"
IMAGE_NAME="Cirros"
IMAGE_URL="http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img"
if openstack image list -f csv -c Name | tail -n +2 | grep -q ${IMAGE_NAME}; then
    echo "${IMAGE_NAME} is already loaded into glance"
else
wget ${IMAGE_URL} -O tmp.image
openstack image create \
--file tmp.image \
--public \
--container-format=bare \
--disk-format=qcow2 \
${IMAGE_NAME}
rm -rf tmp.image
fi
