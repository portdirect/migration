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
# Gnocchi Settings
: ${MISTRAL_API_SERVICE_HOSTNAME:="mistral"}
: ${MISTRAL_API_SERVICE_HOST:="${MISTRAL_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME


check_required_vars MISTRAL_KEYSTONE_USER MISTRAL_KEYSTONE_PASSWORD \
                    MISTRAL_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining Keystone Service Endoints"
################################################################################
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"



################################################################################
echo "${OS_DISTRO}: Cinder: Managing User Accounts"
################################################################################

USER=${MISTRAL_KEYSTONE_USER}
ROLE="admin"
DESCRIPTION="${OS_DISTRO}: ${USER} user"
EMAIL="${USER}@${OS_DOMAIN}"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${MISTRAL_KEYSTONE_PASSWORD}

openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          user create --or-show \
                      --domain default \
                      --project-domain default \
                      --project ${PROJECT} \
                      --description "${DESCRIPTION}" \
                      --email "${EMAIL}" \
                      --password ${PASSWORD} \
                      --enable \
                      ${USER}
USER_ID=$(openstack --os-identity-api-version 3 \
                    --os-url ${SERVICE_ENDPOINT} \
                    --os-token ${SERVICE_TOKEN}  \
                    user show --domain default \
                              -f value -c id \
                                ${USER})


################################################################################
echo "${OS_DISTRO}: Cinder: Managing User Roles"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role add --user ${USER_ID} \
                --project-domain default \
                --project ${PROJECT} \
                ${ROLE}
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role assignment list \
                --project-domain default \
                --project ${PROJECT} \
                --role ${ROLE} \
                --user ${USER_ID}



################################################################################
echo "${OS_DISTRO}: Cinder: Service Management"
################################################################################
SERVICE_NAME=mistral
SERVICE_TYPE=container
SERVICE_DESC="${OS_DISTRO}: $SERVICE_NAME service"
PUBLIC_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://mistral.${OS_DOMAIN}/v1"
INTERNAL_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://mistral.${OS_DOMAIN}/v1"
ADMIN_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://mistral.${OS_DOMAIN}/v1"
(
  (
    (
      SERVICE_ID=$( openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )
      [[ -z ${SERVICE_ID} ]] && \
          ( \
          echo "Service for $SERVICE_NAME not found, creating now" ; \
          openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                service create \
                      --name ${SERVICE_NAME} \
                      --description "${SERVICE_DESC}" \
                      --enable \
                      ${SERVICE_TYPE}

          SERVICE_ID=$( openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )

          ) || ( \
              openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                service show ${SERVICE_NAME} \
          )
    )

    SERVICE_ID=$( openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                service list \
                  -f csv --quote none | grep ",${SERVICE_NAME},${SERVICE_TYPE}$" | sed -e "s/,${SERVICE_NAME},${SERVICE_TYPE}//g" )

    (
      ENDPOINT_INTERFACE=internal
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $INTERNAL_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack --os-identity-api-version 3 \
                    --os-url ${SERVICE_ENDPOINT} \
                    --os-token ${SERVICE_TOKEN}  \
                    endpoint delete ${ENDPOINT_ID}
              )

          openstack --os-identity-api-version 3 \
                    --os-url ${SERVICE_ENDPOINT} \
                    --os-token ${SERVICE_TOKEN}  \
                    endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $INTERNAL_ENDPOINT_URL
    )


    (
      ENDPOINT_INTERFACE=admin
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $ADMIN_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack --os-identity-api-version 3 \
                    --os-url ${SERVICE_ENDPOINT} \
                    --os-token ${SERVICE_TOKEN}  \
                    endpoint delete ${ENDPOINT_ID}
              )

          openstack --os-identity-api-version 3 \
                    --os-url ${SERVICE_ENDPOINT} \
                    --os-token ${SERVICE_TOKEN}  \
                    endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $ADMIN_ENDPOINT_URL
    )


    (
      ENDPOINT_INTERFACE=public
      ################################################################################
      echo "${OS_DISTRO}: $SERVICE_NAME: $ENDPOINT_INTERFACE Endpoint Management"
      ################################################################################
      ENDPOINT_ID=$( openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                endpoint list \
                  -f csv --quote none | grep "$SERVICE_NAME,${SERVICE_TYPE},True,$ENDPOINT_INTERFACE," | cut -d , -f 1 )

          [[ -z $ENDPOINT_ID ]] && \
              ( \
              echo "No existing endpoint found for $ENDPOINT_INTERFACE @ $PUBLIC_ENDPOINT_URL" \
              ) || ( \
              echo "endpoint found" ; \
              openstack --os-identity-api-version 3 \
                    --os-url ${SERVICE_ENDPOINT} \
                    --os-token ${SERVICE_TOKEN}  \
                    endpoint delete ${ENDPOINT_ID}
              )

          openstack --os-identity-api-version 3 \
                    --os-url ${SERVICE_ENDPOINT} \
                    --os-token ${SERVICE_TOKEN}  \
                    endpoint create --region $DEFAULT_REGION \
                              ${SERVICE_ID} \
                              $ENDPOINT_INTERFACE \
                              $PUBLIC_ENDPOINT_URL
    )
  )
)
