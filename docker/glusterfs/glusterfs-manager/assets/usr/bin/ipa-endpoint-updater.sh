#!/bin/bash
set -e
OPENSTACK_COMPONENT="IPA-ENDPOINT_UPDATER"
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


################################################################################
#echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Component Variables"
################################################################################
OPENSTACK_KUBE_SVC_NAME="glusterfs"
OPENSTACK_KUBE_SVC_NAMESPACE="os-${OPENSTACK_KUBE_SVC_NAME}"
OPENSTACK_KUBE_SVC_IP="$(dig +short os-${OPENSTACK_KUBE_SVC_NAME}.${OPENSTACK_KUBE_SVC_NAMESPACE}.svc.${OS_DOMAIN})"
OPENSTACK_FREEIPA_SVC_IP="$(dig +short ${OPENSTACK_KUBE_SVC_NAME}.${OS_DOMAIN})"
OPENSTACK_KUBE_SVC_IP_SORTED="$(echo $OPENSTACK_KUBE_SVC_IP | tr " " "\n" | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | tr "\n" " ")"
OPENSTACK_FREEIPA_SVC_IP_SORTED="$(echo $OPENSTACK_FREEIPA_SVC_IP | tr " " "\n" | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | tr "\n" " ")"


update_service_ip () {
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: UPDATING SERVICE"
  ################################################################################
  FREEIPA_CONTAINER_NAME=$(cat /etc/ipa/default.conf | grep "^server =" | awk '{print $NF}' | sed "s/.${OS_DOMAIN}//")
  docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "echo \"${IPA_USER_ADMIN_PASSWORD}\" | kinit $IPA_USER_ADMIN_USER"

  # Remove any A records from IPA not in kubernetes
  IPA_IP_ADDRESSES=$(docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-show $(hostname -d) ${OPENSTACK_KUBE_SVC_NAME}" | grep "A record:" | tr -d '[a-z][A-Z],:')
  for IP in $OPENSTACK_KUBE_SVC_IP; do
    IPA_IP_ADDRESSES=$(echo $IPA_IP_ADDRESSES | sed "s/${IP}//" )
  done
  for IP in $IPA_IP_ADDRESSES; do
    docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-del $(hostname -d) ${OPENSTACK_KUBE_SVC_NAME} --a-rec=${IP}"
  done

  # Add all services to IPA not in kubernetes
  for IP in $OPENSTACK_KUBE_SVC_IP; do
    docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-show $(hostname -d) ${OPENSTACK_KUBE_SVC_NAME} --raw" | grep "arecord" | grep -q "${IP}" || \
    docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "ipa dnsrecord-add $(hostname -d) ${OPENSTACK_KUBE_SVC_NAME} --a-rec=${IP}"
  done

 docker exec ${FREEIPA_CONTAINER_NAME} /bin/bash -c "kdestroy"
}


if [ "${OPENSTACK_KUBE_SVC_IP_SORTED}" == "${OPENSTACK_FREEIPA_SVC_IP_SORTED}" ]; then
  ################################################################################
  echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: NO UPDATE REQUIRED"
  ################################################################################
else
  update_service_ip
fi
