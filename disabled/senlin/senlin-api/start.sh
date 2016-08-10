#!/bin/bash
OPENSTACK_COMPONENT="senlin"
COMPONENT_SUBCOMPONET="api"

################################################################################
echo "${OS_DISTRO}: Global Configuration"
################################################################################
. /opt/harbor/harbor-common.sh
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Common Configuration"
################################################################################
. /opt/harbor/config-senlin.sh



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${COMPONENT_SUBCOMPONET} Configuration"
################################################################################
: ${SENLIN_DB_USER:=senlin}
: ${SENLIN_DB_NAME:=senlin}
: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${CINDER_KEYSTONE_USER:=senlin}
: ${ADMIN_USER:="admin"}
: ${ADMIN_USER_DOMAIN:="default"}
: ${ADMIN_USER_PROJECT_DOMAIN:="default"}
: ${DEFAULT_REGION:="HarborOS"}


check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_ADMIN_SERVICE_HOST \
                    SENLIN_KEYSTONE_PASSWORD





################################################################################
echo "${OS_DISTRO}: Defining Keystone Service Endoints"
################################################################################
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"









################################################################################
echo "${OS_DISTRO}: Cinder: Managing User Accounts"
################################################################################

USER=${SENLIN_KEYSTONE_USER}
ROLE=admin
DESCRIPTION="${OS_DISTRO}: ${USER} user"
EMAIL="${USER}@canny.io"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${SENLIN_KEYSTONE_PASSWORD}

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
(
    ROLE=admin
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
              role assignment list --project ${PROJECT} --user ${USER_ID}
)







################################################################################
echo "${OS_DISTRO}: Cinder: Service Management"
################################################################################
SERVICE_NAME=senlin
SERVICE_TYPE=clustering
SERVICE_DESC="${OS_DISTRO}: $SERVICE_TYPE service"
PUBLIC_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${SENLIN_API_SERVICE_HOST}:${SENLIN_API_SERVICE_PORT}/v1/\$(tenant_id)s"
INTERNAL_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${SENLIN_API_SERVICE_HOST}:${SENLIN_API_SERVICE_PORT}/v1/\$(tenant_id)s"
ADMIN_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${SENLIN_API_SERVICE_HOST}:${SENLIN_API_SERVICE_PORT}/v1/\$(tenant_id)s"
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

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${COMPONENT_SUBCOMPONET}: Launching"
################################################################################

exec /usr/bin/senlin-api --config-file /etc/senlin/senlin.conf