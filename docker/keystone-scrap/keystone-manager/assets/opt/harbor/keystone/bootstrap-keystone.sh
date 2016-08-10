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



export IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars KEYSTONE_ADMIN_TOKEN \
                    KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_ADMIN_SERVICE_PORT \
                    KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_PUBLIC_SERVICE_PORT \
                    IPA_REALM
dump_vars


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Looping back primary keystone API to localhost"
################################################################################
cp -f /etc/hosts /etc/hosts-original
echo "127.0.0.1       ${KEYSTONE_ADMIN_SERVICE_HOST}" >> /etc/hosts
echo "127.0.0.1       ${KEYSTONE_PUBLIC_SERVICE_HOST}" >> /etc/hosts


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining Service Endoints"
################################################################################
# Export Keystone service environment variables
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="https://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"

# File path and name used by crudini tool
export cfg=/etc/keystone/keystone.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Token Configuration"
################################################################################
crudini --set $cfg DEFAULT admin_token "${KEYSTONE_ADMIN_TOKEN}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** STARTING ***"
################################################################################
httpd -k start

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Verifying Keystone is running"
################################################################################
while ! curl -o /dev/null -s --fail ${SERVICE_ENDPOINT}; do
    echo "${OS_DISTRO}: Waiting for Keystone @ ${SERVICE_ENDPOINT}"
    httpd -k start
    sleep 1;
done



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Region Management"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          region create \
                --description "$DEFAULT_REGION" \
                $DEFAULT_REGION \
    || openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          region show $DEFAULT_REGION


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Service Management"
################################################################################
SERVICE_NAME=keystone
SERVICE_TYPE=identity
SERVICE_DESC="${OS_DISTRO}: $SERVICE_TYPE service"
PUBLIC_ENDPOINT_URL="https://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
INTERNAL_ENDPOINT_URL="https://${KEYSTONE_PUBLIC_SERVICE_HOST}/v3"
ADMIN_ENDPOINT_URL="https://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"
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
        ) || ( \
            openstack --os-identity-api-version 3 \
              --os-url ${SERVICE_ENDPOINT} \
              --os-token ${SERVICE_TOKEN}  \
              service show ${SERVICE_NAME} \
        )
  )

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
                            $SERVICE_NAME \
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
                            $SERVICE_NAME \
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
                            $SERVICE_NAME \
                            $ENDPOINT_INTERFACE \
                            $PUBLIC_ENDPOINT_URL
    )
)




################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the default domain"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          domain create --or-show \
                --description "${OS_DISTRO}: default domain" \
                --enable \
                default

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ${KEYSTONE_ADMIN_PROJECT} Project"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          project create --or-show \
                --domain default \
                --description "${OS_DISTRO}: ${KEYSTONE_ADMIN_PROJECT} project" \
                --enable \
                ${KEYSTONE_ADMIN_PROJECT}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ${SERVICE_TENANT_NAME} Project"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          project create --or-show \
                --domain default \
                --description "${OS_DISTRO}: ${SERVICES_TENANT_NAME} project" \
                --enable \
                ${SERVICE_TENANT_NAME}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Managing Roles"
################################################################################
# Admin Role (general)
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role create admin \
    || openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role show admin



# Member role (general)
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role create user \
    || openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role show user



# Heat Stack Owner
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role create heat_stack_owner \
    || openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role show heat_stack_owner
# Heat Stack User
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role create heat_stack_user \
    || openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role show heat_stack_user


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the default domain "admin" (${KEYSTONE_ADMIN_USER}) user"
################################################################################

USER=${KEYSTONE_ADMIN_USER}
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          user create --or-show \
                      --domain default \
                      --project ${KEYSTONE_ADMIN_PROJECT} \
                      --description "${OS_DISTRO}: Openstack admin user" \
                      --email "openstack-admin@${OS_DOMAIN}" \
                      --password ${KEYSTONE_ADMIN_PASSWORD} \
                      --enable \
                      ${USER}
USER_ID=$(openstack --os-identity-api-version 3 \
                                  --os-url ${SERVICE_ENDPOINT} \
                                  --os-token ${SERVICE_TOKEN}  \
                                  user show --domain default \
                                            -f value -c id \
                                              ${USER})

PROJECT=${KEYSTONE_ADMIN_PROJECT}
# ROLE=user
# (
#     openstack --os-identity-api-version 3 \
#               --os-url ${SERVICE_ENDPOINT} \
#               --os-token ${SERVICE_TOKEN}  \
#               role add --user ${USER_ID} \
#                     --project-domain default \
#                     --project ${KEYSTONE_ADMIN_PROJECT} \
#                     ${ROLE}
#     openstack --os-identity-api-version 3 \
#               --os-url ${SERVICE_ENDPOINT} \
#               --os-token ${SERVICE_TOKEN}  \
#               role assignment list \
#                     --project-domain default \
#                     --project ${KEYSTONE_ADMIN_PROJECT} \
#                     --role ${ROLE} \
#                     --user ${USER_ID}
# )

ROLE=admin
(
    openstack --os-identity-api-version 3 \
              --os-url ${SERVICE_ENDPOINT} \
              --os-token ${SERVICE_TOKEN}  \
              role add --user ${USER_ID} \
                    --project-domain default \
                    --project ${KEYSTONE_ADMIN_PROJECT} \
                    ${ROLE}
    openstack --os-identity-api-version 3 \
              --os-url ${SERVICE_ENDPOINT} \
              --os-token ${SERVICE_TOKEN}  \
              role assignment list \
                    --project-domain default \
                    --project ${KEYSTONE_ADMIN_PROJECT} \
                    --role ${ROLE} \
                    --user ${USER_ID}
)

ROLE=heat_stack_owner
(
    openstack --os-identity-api-version 3 \
              --os-url ${SERVICE_ENDPOINT} \
              --os-token ${SERVICE_TOKEN}  \
              role add --user ${USER_ID} \
                    --project-domain default \
                    --project ${KEYSTONE_ADMIN_PROJECT} \
                    ${ROLE}
    openstack --os-identity-api-version 3 \
              --os-url ${SERVICE_ENDPOINT} \
              --os-token ${SERVICE_TOKEN}  \
              role assignment list \
                    --project-domain default \
                    --project ${KEYSTONE_ADMIN_PROJECT} \
                    --role ${ROLE} \
                    --user ${USER_ID}
)





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating openrc file for ${KEYSTONE_ADMIN_USER}"
################################################################################
cat > /openrc_${KEYSTONE_ADMIN_USER}-default <<EOF
export OS_USERNAME=${KEYSTONE_ADMIN_USER}
export OS_PASSWORD=${KEYSTONE_ADMIN_PASSWORD}
export OS_AUTH_URL=$SERVICE_ENDPOINT
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=${DEFAULT_REGION}
export OS_PROJECT_NAME=${KEYSTONE_ADMIN_PROJECT}
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export PS1="[(\${OS_USERNAME}@\${OS_PROJECT_DOMAIN_NAME}/\${OS_PROJECT_NAME}) \\u@\\h \\W] ⌘ "
EOF









################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** STARTING ***"
################################################################################
httpd -k stop



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Token Configuration"
################################################################################
crudini --del $cfg DEFAULT admin_token





################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** STARTING ***"
################################################################################
httpd -k start



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Verifying Keystone is running"
################################################################################
while ! curl -o /dev/null -s --fail ${SERVICE_ENDPOINT}; do
    echo "${OS_DISTRO}: Waiting for Keystone @ ${SERVICE_ENDPOINT}"
    httpd -k start
    sleep 1;
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing Admin Credentials and ckecking we can get a token"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default
openstack token issue


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Stopping Local Server"
################################################################################
httpd -k stop
/bin/cp -f /etc/hosts-original /etc/hosts


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sourcing Admin Credentials and ckecking we can get a token from the real keystone servers"
################################################################################
source /openrc_${KEYSTONE_ADMIN_USER}-default
openstack token issue
