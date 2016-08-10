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
: ${TROVE_SUBNET_ADDR:="100.68.0.0"}
TROVE_SUBNET_RANGE="${TROVE_SUBNET_ADDR}/${OPENSTACK_PUBLIC_RANGE}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating Network"
################################################################################
fail_unless_db



source openrc
SERVICE_TENANT_ID=$(openstack project show --domain=default services -f value -c id)

neutron net-show 'Trove' || neutron net-create --tenant-id $SERVICE_TENANT_ID 'Trove' | grep ' id ' | awk '{print $4}'
TROVE_NET_ID="$(neutron net-show 'Trove' | grep ' id ' | awk '{print $4}' )"
neutron net-show $TROVE_NET_ID

#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting TROVE NETWORK ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/management_network_id $TROVE_NET_ID


neutron subnet-show 'Trove_Subnet' || neutron subnet-create --tenant-id $SERVICE_TENANT_ID --dns-nameserver 8.8.8.8  --gateway 100.68.0.1 --ip_version 4 --name 'Trove_Subnet'  ${TROVE_NET_ID} ${TROVE_SUBNET_RANGE} | grep ' id ' | awk '{print $4}'
TROVE_SUBNET_ID="$(neutron subnet-show 'Trove_Subnet' | grep ' id ' | awk '{print $4}')"
neutron subnet-show $TROVE_SUBNET_ID

#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting TROVE NETWORK ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/management_subnet_id $TROVE_SUBNET_ID



neutron router-show 'Trove_Router' || neutron router-create --tenant-id $SERVICE_TENANT_ID 'Trove_Router'
TROVE_ROUTER_ID="$(neutron router-show 'Trove_Router' | grep ' id ' | awk '{print $4}')"

neutron router-gateway-set $TROVE_ROUTER_ID 'External'
neutron router-interface-add $TROVE_ROUTER_ID ${TROVE_SUBNET_ID} || true

neutron router-show $TROVE_ROUTER_ID
#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting TROVE ROUTER ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/management_router_id $TROVE_ROUTER_ID
