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
: ${OPENSTACK_PUBLIC_RANGE:="16"}
: ${MANILA_SUBNET_ADDR:="100.66.0.0"}
MANILA_SUBNET_RANGE="${MANILA_SUBNET_ADDR}/${OPENSTACK_PUBLIC_RANGE}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating Network"
################################################################################
fail_unless_db



source openrc
SERVICE_TENANT_ID=$(openstack project show --domain=default services -f value -c id)

neutron net-show 'Manila' || neutron net-create --tenant-id $SERVICE_TENANT_ID 'Manila' | grep ' id ' | awk '{print $4}'
MANILA_NET_ID="$(neutron net-show 'Manila' | grep ' id ' | awk '{print $4}' )"
neutron net-show $MANILA_NET_ID

#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting MANILA NETWORK ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/admin_network_id $MANILA_NET_ID

neutron subnet-show 'Manila_Subnet' || neutron subnet-create --dns-nameserver 8.8.8.8 --tenant-id $SERVICE_TENANT_ID --ip_version 4 --name 'Manila_Subnet' --subnetpool None ${MANILA_NET_ID} ${MANILA_SUBNET_RANGE} | grep ' id ' | awk '{print $4}'
MANILA_SUBNET_ID="$(neutron subnet-show 'Manila_Subnet' | grep ' id ' | awk '{print $4}')"
neutron subnet-show $MANILA_SUBNET_ID

#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting MANILA NETWORK ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/admin_subnet_id $MANILA_SUBNET_ID



neutron router-show 'Manila_Router' || neutron router-create --tenant-id $SERVICE_TENANT_ID 'Manila_Router'
MANILA_ROUTER_ID="$(neutron router-show 'Manila_Router' | grep ' id ' | awk '{print $4}')"

neutron router-gateway-set $MANILA_ROUTER_ID 'External'
neutron router-interface-add $MANILA_ROUTER_ID ${MANILA_SUBNET_ID} || true

neutron router-show $MANILA_ROUTER_ID
#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting MANILA ROUTER ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/admin_router_id $MANILA_ROUTER_ID
