#!/bin/bash

OPENSTACK_COMPONENT=freeipa
OPENSTACK_SUBCOMPONENT=master

source /etc/os-common/common.env
source /etc/${OPENSTACK_COMPONENT}/${OPENSTACK_SUBCOMPONENT}.env
source /etc/${OPENSTACK_COMPONENT}/credentials-admin.env
source /etc/${OPENSTACK_COMPONENT}/credentials-ds.env

IPA_HOSTNAME=${IPA_MASTER_HOSTNAME}.${OS_DOMAIN}


IPA_SERVER_ID=$(/bin/docker-compose -f /etc/${OPENSTACK_COMPONENT}/${OPENSTACK_SUBCOMPONENT}.yml ps -q)
IPA_MASTER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${IPA_SERVER_ID})



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For DNS to be active"
################################################################################
STATUS="DOWN"
while [ "$STATUS" != "OK" ]
do
  DNS_RESPONSE=$(dig @$IPA_MASTER_IP $IPA_HOSTNAME | awk '/ANSWER SECTION/ { getline; print }' | awk -F' ' '{print $5}')
  if [ "${DNS_RESPONSE}" != "$IPA_MASTER_IP" ]; then
    echo "${OS_DISTRO}: IPA: Not Yet Replying to DNS QUERIES"
    STATUS="DOWN"
  else
    echo "${OS_DISTRO}: IPA: DNS now resolving"
    STATUS="OK"
  fi
  sleep 1s
done



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Saving IPA Server master IP"
################################################################################
echo "IPA_MASTER_IP=${IPA_MASTER_IP}" > /etc/ipa/master-ip.generated.env
