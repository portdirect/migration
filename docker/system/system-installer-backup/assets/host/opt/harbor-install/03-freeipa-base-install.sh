#!/bin/sh
export PATH=/usr/local/bin:${PATH}

KUBECTL=/usr/local/bin/kubectl
HARBOR_DOCKER=/usr/local/bin/harbor-docker
HOST_WORK_DIR=/tmp/openstack

IPA_DATA_DIR=/var/lib/freeipa-master
DNS_FOWARDER=8.8.8.8
DNS_FOWARDER_1=8.8.4.4

update_harbor_dist () {

  ${HARBOR_DOCKER} kill openstack-install || true
  ${HARBOR_DOCKER} rm -v openstack-install || true
  rm -rf ${HOST_WORK_DIR} || true
  mkdir -p ${HOST_WORK_DIR}
  ${HARBOR_DOCKER} pull docker.io/port/system-openstack:latest
  ${HARBOR_DOCKER} run -d --name openstack-install --net=host -v /:/host docker.io/port/system-openstack:latest tail -f /dev/null

}
update_harbor_dist


${HARBOR_DOCKER} exec openstack-install /bin/cp -rf /opt/harbor/assets/host/bin/openstack-env-gen.sh /host/usr/local/bin/


rm -rf ${IPA_DATA_DIR}
/usr/local/bin/openstack-env-gen.sh
source /etc/openstack/openstack.env




OS_HOSTNAME_SHORT=freeipa-master
OS_DOMAIN=$(hostname -d)
ipa-docker kill ${OS_HOSTNAME_SHORT} || echo "Did not remove an IPA server"
ipa-docker rm -v ${OS_HOSTNAME_SHORT} || echo "Did not remove an IPA server"



echo "--allow-zone-overlap" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--setup-dns" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--forwarder=${DNS_FOWARDER}" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--forwarder=${DNS_FOWARDER_1}" >> ${IPA_DATA_DIR}/ipa-server-install-options
echo "--auto-reverse" >> ${IPA_DATA_DIR}/ipa-server-install-options
for BRIDGE_DEVICE in br0 br1 br2 docker0; do
  # do something
  BRIDGE_IP=$(ip -f inet -o addr show ${BRIDGE_DEVICE}|cut -d\  -f 7 | cut -d/  -f 1)
  REVERSE_ZONE=$(echo ${BRIDGE_IP} | awk -F. '{print $3"." $2"."$1".in-addr.arpa."}')
  echo "--reverse-zone=${REVERSE_ZONE}" >> ${IPA_DATA_DIR}/ipa-server-install-options
done



IPA_BRIDGE_IP=$(ip -f inet -o addr show br0|cut -d\  -f 7 | cut -d/  -f 1)

ipa-docker run -it \
 --hostname=${OS_HOSTNAME_SHORT}.${OS_DOMAIN} \
 --name=${OS_HOSTNAME_SHORT} \
 -v ${IPA_DATA_DIR}:/data:rw \
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
 --dns=${DNS_FOWARDER} \
 -e OS_DOMAIN=${OS_DOMAIN} \
 -p ${IPA_BRIDGE_IP}:533:53/udp -p ${IPA_BRIDGE_IP}:533:53/tcp \
 port/docker-freeipa-centos-7-upstream:latest exit-on-finished
ipa-docker rm -v ${OS_HOSTNAME_SHORT} || echo "Did not remove an IPA server"

systemctl restart harbor-freeipa
systemctl enable harbor-freeipa

source /etc/openstack/openstack.env
# This takes a lot longer than you would think (could be 30 mins), hang in there
ipa-docker exec ${OS_HOSTNAME_SHORT} /sbin/ipa-kra-install --no-host-dns --verbose -U -p ${IPA_DS_PASSWORD}




# Now we need to enroll the host with the ipa server
export PATH=/usr/local/bin:${PATH}
source /etc/openstack/openstack.env
MASTER_IP=$(ip -f inet -o addr show br0|cut -d\  -f 7 | cut -d/  -f 1)
ipa-client-install \
 --hostname=$(hostname -s).$(hostname -d) \
 --enable-dns-updates \
 --request-cert \
 --no-ntp \
 --force-join \
 --unattended \
 --principal="admin" \
 --password="${IPA_ADMIN_PASSWORD}"
