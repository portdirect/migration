#!/bin/bash
tail -f /dev/null


source /etc/openstack/openstack.env

export PATH=/usr/local/bin:${PATH}
IPSILON_DATA_DIR=/var/lib/ipsilon-master
mkdir -p ${IPSILON_DATA_DIR}
cat > ${IPSILON_DATA_DIR}/os-container.env << EOF
IPA_USER_ADMIN_USER=${IPA_USER_ADMIN_USER}
IPA_USER_ADMIN_PASSWORD=${IPA_USER_ADMIN_PASSWORD}
IPA_HOST_ADMIN_USER=${IPA_USER_ADMIN_USER}
IPA_HOST_ADMIN_PASSWORD=${IPA_HOST_ADMIN_PASSWORD}
EOF

ipa-docker run -it --rm -v ${IPSILON_DATA_DIR}/os-container.env:/etc/os-config/container.env:ro -e OS_DOMAIN=port.direct --hostname=ipsilon.port.direct port/ipsilon-server:latest bash

source /etc/os-container.env
echo "${IPA_HOST_ADMIN_PASSWORD}" | kinit "${IPA_HOST_ADMIN_USER}"
ipsilon-server-install --ipa=yes --gssapi=yes --form=yes --info-sssd=yes --admin-user=${IPA_HOST_ADMIN_USER}
httpd -D FOREGROUND
