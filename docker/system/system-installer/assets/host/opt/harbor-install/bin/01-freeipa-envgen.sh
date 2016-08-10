#!/bin/bash
set -e
PATH=${PATH}:/usr/local/bin
source /etc/harbor/network.env
source /etc/harbor/auth.env

IPA_DATA_DIR=/var/lib/harbor/freeipa/master
mkdir -p ${IPA_DATA_DIR}
echo "--allow-zone-overlap" > ${IPA_DATA_DIR}/ipa-server-install-options
echo "--setup-dns" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--forwarder=${EXTERNAL_DNS}" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--forwarder=${EXTERNAL_DNS_1}" >> ${IPA_DATA_DIR}/ipa-server-install-options
for BRIDGE_IP in ${CALICO_NETWORK} ${KUBE_SVC_NETWORK} ${FLANNEL_WAN_NETWORK} ${FLANNEL_CORE_NETWORK}; do
  # do something
  REVERSE_ZONE=$(echo ${BRIDGE_IP} | awk -F. '{print $3"." $2"."$1".in-addr.arpa."}')
  echo "--reverse-zone=${REVERSE_ZONE}" >> ${IPA_DATA_DIR}/ipa-server-install-options
done
echo "--ds-password=${IPA_DS_PASSWORD}" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--admin-password=${IPA_ADMIN_PASSWORD}" >> ${IPA_DATA_DIR}/ipa-server-install-options

docker run -t \
    --hostname=freeipa-master.${OS_DOMAIN} \
    --privileged \
    --name=freeipa-master \
    -v ${IPA_DATA_DIR}:/data:rw \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --dns=${EXTERNAL_DNS} \
    -e OS_DOMAIN=${OS_DOMAIN} \
    docker.io/port/ipa-server:latest exit-on-finished
