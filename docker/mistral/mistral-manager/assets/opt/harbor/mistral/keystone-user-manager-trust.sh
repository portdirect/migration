#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=trust
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
: ${DEFAULT_DOMAIN:="default"}
: ${TRUST_DOMAIN:="mistral"}
: ${MISTRAL_KEYSTONE_TRUST_PASSWORD:="${MISTRAL_KEYSTONE_PASSWORD}"}

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars IPA_USER_ADMIN_PASSWORD IPA_USER_ADMIN_USER ETCDCTL_ENDPOINT

check_required_vars MISTRAL_KEYSTONE_USER MISTRAL_KEYSTONE_TRUST_PASSWORD

check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME

dump_vars





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining Keystone Service Endoints"
################################################################################
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing \"${TRUST_DOMAIN}\" domain"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          domain create --or-show \
              --description "${OS_DISTRO}: ${TRUST_DOMAIN} domain" \
              ${TRUST_DOMAIN}

TRUST_DOMAIN_ID=$( openstack --os-identity-api-version 3 \
                            --os-url ${SERVICE_ENDPOINT} \
                            --os-token ${SERVICE_TOKEN}  \
                            domain show -f value -c id ${TRUST_DOMAIN} )

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ETCD set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/trust-domain-id ${TRUST_DOMAIN_ID}"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/trust-domain-id "${TRUST_DOMAIN_ID}"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing domain admin"
################################################################################
USER="${MISTRAL_KEYSTONE_USER}_admin"
ROLE=admin
DESCRIPTION="${OS_DISTRO}: ${USER} user"
EMAIL="${USER}@${OS_DOMAIN}"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${MISTRAL_KEYSTONE_TRUST_PASSWORD}

openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          user create --or-show \
                      --domain ${TRUST_DOMAIN} \
                      --description "${DESCRIPTION}" \
                      --email "${EMAIL}" \
                      --password ${PASSWORD} \
                      --enable \
                      ${USER}

USER_ID=$(openstack --os-identity-api-version 3 \
                                --os-url ${SERVICE_ENDPOINT} \
                                --os-token ${SERVICE_TOKEN}  \
                                user show --domain ${TRUST_DOMAIN} \
                                          -f value -c id \
                                            ${USER})


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: ETCD set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/trust-user-id ${USER_ID}"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/trust-user-id "${USER_ID}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing domain admin: ROLES"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role add --domain ${TRUST_DOMAIN} \
                   --user ${USER_ID} \
                   ${ROLE}
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role assignment list --user ${USER_ID}
