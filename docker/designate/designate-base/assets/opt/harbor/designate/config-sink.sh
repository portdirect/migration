#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=sink
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh
. /opt/harbor/designate/common-vars.sh
: ${DEFAULT_REGION:="HarborOS"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars ETCDCTL_ENDPOINT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting DESIGNATE_MANAGED_DNS_DOMAIN_ID"
################################################################################
#DESIGNATE_ADMIN_DOMAIN_ID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_admin_domain_id)"
DESIGNATE_MANAGED_DNS_DOMAIN_ID=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_managed_dns_domain_id)
check_required_vars DESIGNATE_MANAGED_DNS_DOMAIN_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting DESIGNATE_INTERNAL_DNS_DOMAIN_ID"
################################################################################
#DESIGNATE_ADMIN_DOMAIN_ID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_admin_domain_id)"
DESIGNATE_INTERNAL_DNS_DOMAIN_ID=$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_internal_dns_domain_id)
check_required_vars DESIGNATE_INTERNAL_DNS_DOMAIN_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: SINK CONFIG"
################################################################################
crudini --set $cfg service:sink enabled_notification_handlers "nova_fixed, neutron_floatingip"

crudini --set $cfg handler:neutron_floatingip zone_id "${DESIGNATE_MANAGED_DNS_DOMAIN_ID}"
crudini --set $cfg handler:neutron_floatingip domain_id "${DESIGNATE_MANAGED_DNS_DOMAIN_ID}"
crudini --set $cfg handler:neutron_floatingip notification_topics "notifications_dns"
crudini --set $cfg handler:neutron_floatingip control_exchange "neutron"
crudini --set $cfg handler:neutron_floatingip format "%(octet0)s-%(octet1)s-%(octet2)s-%(octet3)s.%(zone)s"


crudini --set $cfg handler:nova_fixed zone_id "${DESIGNATE_INTERNAL_DNS_DOMAIN_ID}"
crudini --set $cfg handler:nova_fixed domain_id "${DESIGNATE_INTERNAL_DNS_DOMAIN_ID}"
crudini --set $cfg handler:nova_fixed notification_topics "notifications_dns"
crudini --set $cfg handler:nova_fixed control_exchange "nova"
crudini --set $cfg handler:nova_fixed format '%(hostname)s.%(project)s.%(zone)s'
