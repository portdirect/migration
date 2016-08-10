#!/bin/bash
set -e

################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
: ${DESIGNATE_POOL_ID:="794ccc2c-d751-44fe-b57f-8894c9f5c842"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars OS_DOMAIN


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating Domain For Users: Designate needs to be restarted after the inital management run for this to propogate"
################################################################################
source openrc
export OS_CACERT=/etc/ipa/ca.crt

designate domain-get ex.${OS_DOMAIN}. || designate domain-create \
      --name ex.${OS_DOMAIN}. \
      --email admin@${OS_DOMAIN} \
      --ttl 300 \
      --description "Managed Floating IP Domain, populated from Neutron/Nova events"

DESIGNATE_MANAGED_DNS_DOMAIN_ID=$(designate domain-get ex.${OS_DOMAIN}. -f value -c id)
if [ "$DESIGNATE_MANAGED_DNS_DOMAIN_ID" == "None" ]; then exit 1; fi


designate domain-get in.${OS_DOMAIN}. || designate domain-create \
      --name in.${OS_DOMAIN}. \
      --email admin@${OS_DOMAIN} \
      --ttl 300 \
      --description "Managed Internal Domain, populated from Neutron/Nova events"

DESIGNATE_INTERNAL_DNS_DOMAIN_ID=$(designate domain-get in.${OS_DOMAIN}. -f value -c id)
if [ "$DESIGNATE_INTERNAL_DNS_DOMAIN_ID" == "None" ]; then exit 1; fi


designate domain-get ${OS_DOMAIN}. || designate domain-create \
      --name ${OS_DOMAIN}. \
      --email admin@${OS_DOMAIN} \
      --ttl 3600 \
      --description "Primary DNS Domain"

DESIGNATE_DNS_DOMAIN_ID=$(designate domain-get ${OS_DOMAIN}. -f value -c id)
if [ "$DESIGNATE_DNS_DOMAIN_ID" == "None" ]; then exit 1; fi

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars ETCDCTL_ENDPOINT DESIGNATE_MANAGED_DNS_DOMAIN_ID DESIGNATE_INTERNAL_DNS_DOMAIN_ID DESIGNATE_INTERNAL_DNS_DOMAIN_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting DESIGNATE_MANAGED_DNS_DOMAIN_ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_managed_dns_domain_id ${DESIGNATE_MANAGED_DNS_DOMAIN_ID}
etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_managed_dns_domain_id

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting DESIGNATE_INTERNAL_DNS_DOMAIN_ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_internal_dns_domain_id ${DESIGNATE_INTERNAL_DNS_DOMAIN_ID}
etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_internal_dns_domain_id
