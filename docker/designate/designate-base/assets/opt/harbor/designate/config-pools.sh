#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=pools-backends
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/designate/common-vars.sh
: ${DEFAULT_REGION:="HarborOS"}

: ${DESIGNATE_API_SERVICE_HOSTNAME:="designate"}
: ${DESIGNATE_API_SERVICE_HOST:="${DESIGNATE_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}

: ${DESIGNATE_DNS_SERVICE_HOSTNAME:="designate-dns.os-designate.svc.$OS_DOMAIN"}
: ${DESIGNATE_MDNS_SERVICE_HOSTNAME:="designate-mdns.os-designate.svc.$OS_DOMAIN"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting DNS SERVICE IP"
################################################################################
n=0
until [ $n -ge 5 ]
do
  if [[ $(dig +short designate-dns.os-designate.svc.$OS_DOMAIN | head -n1) ]]; then
      echo "Kube is returning an IP" && break
  fi
   n=$[$n+1]
   ################################################################################
   echo "${OS_DISTRO}: Waiting for Kube attempt $n of 5"
   ################################################################################
   sleep 5
done
DESIGNATE_DNS_SERVICE_SVC_IP="$(dig +short designate-dns.os-designate.svc.$OS_DOMAIN | head -n1)"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting MDNS SERVICE IP"
################################################################################
n=0
until [ $n -ge 5 ]
do
  if [[ $(dig +short designate-mdns.os-designate.svc.$OS_DOMAIN | head -n1) ]]; then
      echo "Kube is returning an IP" && break
  fi
   n=$[$n+1]
   ################################################################################
   echo "${OS_DISTRO}: Waiting for Kube attempt $n of 5"
   ################################################################################
   sleep 5
done
DESIGNATE_MDNS_SERVICE_SVC_IP="$(dig +short designate-mdns.os-designate.svc.$OS_DOMAIN | head -n1)"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars DESIGNATE_DNS_SERVICE_SVC_IP DESIGNATE_MDNS_SERVICE_SVC_IP


: ${DESIGNATE_POOL_ID:="794ccc2c-d751-44fe-b57f-8894c9f5c842"}
: ${DESIGNATE_POOL_NAMESERVERS_ID:="0f66b842-96c2-4189-93fc-1dc95a08b012"}
: ${DESIGNATE_POOL_TARGETS_ID:="f26e0b32-736f-4f0a-831b-039a415c481e"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg DESIGNATE_DNS_SERVICE_SVC_IP DESIGNATE_MDNS_SERVICE_SVC_IP DESIGNATE_POOL_ID DESIGNATE_POOL_NAMESERVERS_ID DESIGNATE_POOL_TARGETS_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting Domain ID from ETCD"
################################################################################
DESIGNATE_ADMIN_PROJECT_ID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_admin_project_id)"
check_required_vars DESIGNATE_ADMIN_PROJECT_ID DESIGNATE_POOL_ID

crudini --set $cfg service:central managed_resource_tenant_id "${DESIGNATE_ADMIN_PROJECT_ID}"
crudini --set $cfg service:central managed_resource_email "hostmaster@${OS_DOMAIN}."
crudini --set $cfg service:central default_pool_id "${DESIGNATE_POOL_ID}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DNS POOLS"
################################################################################
crudini --set $cfg service:pool_manager pool_id "${DESIGNATE_POOL_ID}"
crudini --set $cfg pool:${DESIGNATE_POOL_ID} nameservers "${DESIGNATE_POOL_NAMESERVERS_ID}"
crudini --set $cfg pool:${DESIGNATE_POOL_ID} targets "${DESIGNATE_POOL_TARGETS_ID}"
crudini --set $cfg pool:${DESIGNATE_POOL_ID} also_notifies ""

crudini --set $cfg pool_nameserver:${DESIGNATE_POOL_NAMESERVERS_ID} port "553"
crudini --set $cfg pool_nameserver:${DESIGNATE_POOL_NAMESERVERS_ID} host "${DESIGNATE_DNS_SERVICE_SVC_IP}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        DESIGNATE_PDNS_DB_USER DESIGNATE_PDNS_DB_PASSWORD DESIGNATE_PDNS_DB_NAME


crudini --set $cfg pool_target:${DESIGNATE_POOL_TARGETS_ID} options "connection: mysql://${DESIGNATE_PDNS_DB_USER}:${DESIGNATE_PDNS_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DESIGNATE_PDNS_DB_NAME}?charset=utf8"
crudini --set $cfg pool_target:${DESIGNATE_POOL_TARGETS_ID} masters "${DESIGNATE_MDNS_SERVICE_SVC_IP}:5354"
crudini --set $cfg pool_target:${DESIGNATE_POOL_TARGETS_ID} "type" "powerdns"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Writing Config Yaml"
################################################################################
cat > /etc/designate/pools.yaml <<EOF
- name: default
  description: Harbor PowerDNS Pool
  attributes: {}

  ns_records:
    - hostname: ns1.${OS_DOMAIN}.
      priority: 1

  nameservers:
    - host: ${DESIGNATE_DNS_SERVICE_SVC_IP}
      port: 553

  targets:
    - type: powerdns
      description: PowerDNS Database Cluster

      masters:
        - host: ${DESIGNATE_MDNS_SERVICE_SVC_IP}
          port: 5354

      options:
        host: ${DESIGNATE_DNS_SERVICE_SVC_IP}
        port: 553
        connection: mysql://${DESIGNATE_PDNS_DB_USER}:${DESIGNATE_PDNS_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${DESIGNATE_PDNS_DB_NAME}?charset=utf8
EOF
chown designate /etc/designate/pools.yaml
