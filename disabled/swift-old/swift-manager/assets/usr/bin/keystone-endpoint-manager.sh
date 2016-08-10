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


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_AUTH_PROTOCOL KEYSTONE_ADMIN_SERVICE_HOST \
                    SERVICE_TENANT_NAME


check_required_vars SWIFT_KEYSTONE_USER SWIFT_KEYSTONE_PASSWORD \
                    SWIFT_API_SERVICE_HOST


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining Keystone Service Endoints"
################################################################################
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"


################################################################################
echo "${OS_DISTRO}: Swift: Managing User Accounts"
################################################################################

USER=${SWIFT_KEYSTONE_USER}
ROLE="admin"
DESCRIPTION="${OS_DISTRO}: ${USER} user"
EMAIL="${USER}@${OS_DOMAIN}"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${SWIFT_KEYSTONE_PASSWORD}

openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          user create --or-show \
                      --domain default \
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
echo "${OS_DISTRO}: Swift: Managing User Roles"
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
              role assignment list --project ${PROJECT} --role ${ROLE} --user ${USER_ID}






################################################################################
echo "${OS_DISTRO}: Swift: Service Management"
################################################################################


SERVICE_NAME=swift
SERVICE_TYPE=object-store
SERVICE_DESC="${OS_DISTRO}: $SERVICE_TYPE service"
INTERNAL_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://swift.${OS_DOMAIN}/v1/AUTH_%(tenant_id)s"
PUBLIC_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://swift.${OS_DOMAIN}/v1/AUTH_%(tenant_id)s"
ADMIN_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://swift.${OS_DOMAIN}/"
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





























################################################################################
echo "${OS_DISTRO}: Swift: Service Management"
################################################################################


SERVICE_NAME=s3
SERVICE_TYPE=s3
SERVICE_DESC="${OS_DISTRO}: $SERVICE_TYPE service"
INTERNAL_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://swift.${OS_DOMAIN}"
PUBLIC_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://swift.${OS_DOMAIN}"
ADMIN_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://swift.${OS_DOMAIN}"
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
                      -f csv --quote none | grep "$ENDPOINT_INTERFACE,$INTERNAL_ENDPOINT_URL\$" | cut -d , -f 1 )

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
                      -f csv --quote none | grep "$ENDPOINT_INTERFACE,$ADMIN_ENDPOINT_URL\$" | cut -d , -f 1 )

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
                      -f csv --quote none | grep "$ENDPOINT_INTERFACE,$PUBLIC_ENDPOINT_URL\$" | cut -d , -f 1 )

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
