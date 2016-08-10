#!/bin/bash
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Config"
################################################################################
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


: ${NEUTRON_API_SERVICE_PORT:="9696"}
NEUTRON_SERVER_SERVICE_PORT="${NEUTRON_API_SERVICE_PORT}"
: ${OPENSTACK_PUBLIC_RANGE:="16"}
: ${OPENSTACK_PUBLIC_NET:="100.64.0.0"}
: ${EXTERNAL_NET_NAME:="External"}
: ${EXTERNAL_SUBNET_NAME:="${OS_DOMAIN}"}
: ${GATEWAY_IP:="100.64.0.1"}
: ${DEFAULT_DNS:="100.64.0.1"}
: ${EXTERNAL_POOL_START:="100.64.1.1"}
: ${EXTERNAL_POOL_END:="100.64.254.254"}
EXTERNAL_NET="${OPENSTACK_PUBLIC_NET}/${OPENSTACK_PUBLIC_RANGE}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_os_service_running neutron


################################################################################
echo "${OS_DISTRO}: Neutron: Launching Bootstraper"
################################################################################

      ################################################################################
      echo "${OS_DISTRO}: Networking: Managing External Network"
      ################################################################################
      KEYSTONE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"
      neutron --os-username ${NEUTRON_KEYSTONE_USER} \
              --os-password ${NEUTRON_KEYSTONE_PASSWORD} \
              --os-auth-url ${KEYSTONE_ENDPOINT} \
              --os-region-name ${DEFAULT_REGION} \
              --os-project-name ${SERVICE_TENANT_NAME} \
              --os-project-domain-name default \
              --os-user-domain-name default \
              net-create \
                  --router:external \
                  --provider:physical_network physnet1 \
                  --provider:network_type flat \
                  ${EXTERNAL_NET_NAME} \
              || neutron --os-username ${NEUTRON_KEYSTONE_USER} \
                        --os-password ${NEUTRON_KEYSTONE_PASSWORD} \
                        --os-auth-url ${KEYSTONE_ENDPOINT} \
                        --os-region-name ${DEFAULT_REGION} \
                        --os-project-name ${SERVICE_TENANT_NAME} \
                        --os-project-domain-name default \
                        --os-user-domain-name default \
                        net-show ${EXTERNAL_NET_NAME}


      neutron --os-username ${NEUTRON_KEYSTONE_USER} \
              --os-password ${NEUTRON_KEYSTONE_PASSWORD} \
              --os-auth-url ${KEYSTONE_ENDPOINT} \
              --os-region-name ${DEFAULT_REGION} \
              --os-project-name ${SERVICE_TENANT_NAME} \
              --os-project-domain-name default \
              --os-user-domain-name default  \
              subnet-create \
                  --name ${EXTERNAL_SUBNET_NAME} \
                  --disable-dhcp \
                  --dns-nameserver ${DEFAULT_DNS//\"} \
                  --gateway ${GATEWAY_IP//\"} \
                  --allocation-pool start=${EXTERNAL_POOL_START//\"},end=${EXTERNAL_POOL_END//\"} \
                  ${EXTERNAL_NET_NAME} ${EXTERNAL_NET//\"} \
              || neutron --os-username ${NEUTRON_KEYSTONE_USER} \
                        --os-password ${NEUTRON_KEYSTONE_PASSWORD} \
                        --os-auth-url ${KEYSTONE_ENDPOINT} \
                        --os-region-name ${DEFAULT_REGION} \
                        --os-project-name ${SERVICE_TENANT_NAME} \
                        --os-project-domain-name default \
                        --os-user-domain-name default \
                        subnet-show ${EXTERNAL_SUBNET_NAME}

################################################################################
echo "${OS_DISTRO}: Neutron: Bootstrapper Complete"
################################################################################
