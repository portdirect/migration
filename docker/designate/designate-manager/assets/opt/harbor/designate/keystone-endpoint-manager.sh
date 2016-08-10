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
# Designate Settings
: ${DESIGNATE_API_SERVICE_HOSTNAME:="designate"}
: ${DESIGNATE_API_SERVICE_HOST:="${DESIGNATE_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
: ${DESIGNATE_ADMIN_PROJECT:="designate"}
: ${DESIGNATE_ADMIN_DOMAIN:="designate"}



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_USER KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME


check_required_vars DESIGNATE_KEYSTONE_USER DESIGNATE_KEYSTONE_PASSWORD \
                    DESIGNATE_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing admin credentials for ${KEYSTONE_ADMIN_USER}"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default


################################################################################
echo "${OS_DISTRO}: Cinder: Managing User Accounts"
################################################################################

USER=${DESIGNATE_KEYSTONE_USER}
ROLE="admin"
DESCRIPTION="${OS_DISTRO}: ${USER} user"
EMAIL="${USER}@${OS_DOMAIN}"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${DESIGNATE_KEYSTONE_PASSWORD}

openstack user create --or-show \
                      --domain default \
                      --project-domain default \
                      --project ${PROJECT} \
                      --description "${DESCRIPTION}" \
                      --email "${EMAIL}" \
                      --password ${PASSWORD} \
                      --enable \
                      ${USER}
USER_ID=$(openstack user show --domain default \
                              -f value -c id \
                                ${USER})


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ${KEYSTONE_ADMIN_PROJECT} Project"
################################################################################
DESIGNATE_ADMIN_PROJECT_ID=$(openstack project create --or-show \
                --domain default \
                --description "${OS_DISTRO}: ${DESIGNATE_ADMIN_PROJECT} project" \
                --enable -f value -c id \
                ${DESIGNATE_ADMIN_PROJECT})

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars ETCDCTL_ENDPOINT DESIGNATE_ADMIN_PROJECT_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting DESIGNATE_ADMIN_PROJECT_ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_admin_project_id ${DESIGNATE_ADMIN_PROJECT_ID}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Managing \"${DESIGNATE_ADMIN_DOMAIN}\" domain"
################################################################################
openstack domain create --or-show \
              --description "${OS_DISTRO}: ${DESIGNATE_ADMIN_DOMAIN} Domain" \
              ${DESIGNATE_ADMIN_DOMAIN}

DESIGNATE_ADMIN_DOMAIN_ID=$( openstack domain show -f value -c id ${DESIGNATE_ADMIN_DOMAIN} )


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars ETCDCTL_ENDPOINT DESIGNATE_ADMIN_DOMAIN_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting DESIGNATE_ADMIN_DOMAIN_ID"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/designate_admin_domain_id ${DESIGNATE_ADMIN_DOMAIN_ID}



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Managing User Roles"
################################################################################
openstack role add --user ${USER_ID} \
                --project-domain default \
                --project ${PROJECT} \
                ${ROLE}
openstack role assignment list \
                --project-domain default \
                --project ${PROJECT} \
                --role ${ROLE} \
                --user ${USER_ID}
openstack role add --user ${USER_ID} \
                --project-domain default \
                --project ${DESIGNATE_ADMIN_PROJECT} \
                ${ROLE}
openstack role assignment list \
                --project-domain default \
                --project ${DESIGNATE_ADMIN_PROJECT} \
                --role ${ROLE} \
                --user ${USER_ID}
openstack role add --user ${USER_ID} \
                --domain ${DESIGNATE_ADMIN_DOMAIN_ID} \
                ${ROLE}
openstack role assignment list \
                --domain ${DESIGNATE_ADMIN_DOMAIN_ID} \
                --role ${ROLE} \
                --user ${USER_ID}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Service Management"
################################################################################
SERVICE_NAME=designate
SERVICE_TYPE=dns
SERVICE_DESC="${OS_DISTRO}: $SERVICE_NAME service"
PUBLIC_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://designate.${OS_DOMAIN}/"
INTERNAL_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://designate.${OS_DOMAIN}/"
ADMIN_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://designate.${OS_DOMAIN}/"
(
  (
    (
      SERVICE_ID=$( openstack service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )
      [[ -z ${SERVICE_ID} ]] && \
          ( \
          echo "Service for $SERVICE_NAME not found, creating now" ; \
          openstack service create \
                      --name ${SERVICE_NAME} \
                      --description "${SERVICE_DESC}" \
                      --enable \
                      ${SERVICE_TYPE}

          SERVICE_ID=$( openstack service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )

          ) || ( \
              openstack service show ${SERVICE_NAME} \
          )
    )

    SERVICE_ID=$( openstack service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )

    (
      ENDPOINT_INTERFACE=internal
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $INTERNAL_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $INTERNAL_ENDPOINT_URL
    )


    (
      ENDPOINT_INTERFACE=admin
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $ADMIN_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $ADMIN_ENDPOINT_URL
    )


    (
      ENDPOINT_INTERFACE=public
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $PUBLIC_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack endpoint delete ${ENDPOINT_ID}
              )

          openstack endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $PUBLIC_ENDPOINT_URL
    )
  )
)
