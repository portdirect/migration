#!/bin/bash
set -o errexit
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
# DB Settings
: ${MARIADB_SERVICE_HOST:="${MARIADB_HOSTNAME}.$OS_DOMAIN"}
# Messaging Settings
: ${RABBITMQ_SERVICE_HOST:="${RABBITMQ_HOSTNAME}.$OS_DOMAIN"}
# Keystone Settings
: ${KEYSTONE_ADMIN_SERVICE_HOST:="${KEYSTONE_ADMIN_SERVICE_HOSTNAME}.$OS_DOMAIN"}
: ${KEYSTONE_PUBLIC_SERVICE_HOST:="${KEYSTONE_PUBLIC_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Mistral Settings
: ${MISTRAL_API_SERVICE_HOST:="${MISTRAL_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}



. /opt/harbor/harbor-common.sh
. /opt/harbor/config-mistral.sh

check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_ADMIN_SERVICE_HOST \
                    MISTRAL_KEYSTONE_USER MISTRAL_KEYSTONE_PASSWORD \
                    KEYSTONE_AUTH_PROTOCOL ADMIN_TENANT_NAME \
                    MISTRAL_API_SERVICE_HOST KEYSTONE_ADMIN_SERVICE_PORT \
                    MISTRAL_API_SERVICE_PORT




https://fedorapeople.org/groups/mistral/fedora-21-atomic-5.qcow2





################################################################################
echo "${OS_DISTRO}: Defining Keystone Service Endoints"
################################################################################
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"










################################################################################
echo "${OS_DISTRO}: Mistral: Managing User Accounts"
################################################################################

USER=${MISTRAL_KEYSTONE_USER}
ROLE="admin"
DESCRIPTION="${OS_DISTRO}: ${USER} user"
EMAIL="${USER}@canny.io"
PROJECT=${SERVICE_TENANT_NAME}
PASSWORD=${MISTRAL_KEYSTONE_PASSWORD}

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
echo "${OS_DISTRO}: Mistral: Managing User Roles"
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
echo "${OS_DISTRO}: Mistral: Service Management"
################################################################################
SERVICE_NAME=mistral
SERVICE_TYPE=container
SERVICE_DESC="${OS_DISTRO}: Container ($SERVICE_TYPE) service"
PUBLIC_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${MISTRAL_API_SERVICE_HOST}:${MISTRAL_API_SERVICE_PORT}/v1"
INTERNAL_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${MISTRAL_API_SERVICE_HOST}:${MISTRAL_API_SERVICE_PORT}/v1"
ADMIN_ENDPOINT_URL="${KEYSTONE_AUTH_PROTOCOL}://${MISTRAL_API_SERVICE_HOST}:${MISTRAL_API_SERVICE_PORT}/v1"
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





mysql -h ${MARIADB_SERVICE_HOST} -u root \
	-p${DB_ROOT_PASSWORD} mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${MISTRAL_DB_NAME};
GRANT ALL PRIVILEGES ON ${MISTRAL_DB_NAME}.* TO
	'${MISTRAL_DB_USER}'@'%' IDENTIFIED BY '${MISTRAL_DB_PASSWORD}'
EOF

/usr/bin/mistral-db-manage upgrade







#################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Primed Status"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/primed TRUE


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Management Complete"
################################################################################
tail -f /dev/null
