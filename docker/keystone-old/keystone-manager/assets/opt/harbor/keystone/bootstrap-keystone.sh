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
. /opt/harbor/keystone-vars.sh



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
echo "127.0.0.1       ${KEYSTONE_ADMIN_SERVICE_HOST}" >> /etc/hosts
echo "127.0.0.1       ${KEYSTONE_PUBLIC_SERVICE_HOST}" >> /etc/hosts

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining Service Endoints"
################################################################################
# Export Keystone service environment variables
SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
SERVICE_ENDPOINT="http://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v3"


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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Active @ ${SERVICE_ENDPOINT}"
################################################################################


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Region Management"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          region create \
                --description "$DEFAULT_REGION" \
                --url "http://${OS_DOMAIN}" \
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Domain: Management"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          domain set \
                --description "${OS_DISTRO}: Internal" \
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating the ${SERVICES_TENANT_NAME} Project"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          project create --or-show \
                --domain default \
                --description "${OS_DISTRO}: ${SERVICES_TENANT_NAME} project" \
                --enable \
                ${SERVICES_TENANT_NAME}


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
ROLE=user
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating $IPA_REALM domain"
################################################################################
IPA_REALM_DESCRIPTION="${IPA_REALM}"
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          domain create --description ${IPA_REALM_DESCRIPTION} --enable ${IPA_REALM} \
    || openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          domain show ${IPA_REALM}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Uploading the $IPA_REALM domain config"
################################################################################
keystone-manage --debug --verbose domain_config_upload --domain-name $IPA_REALM \
    || echo "Did not upload config"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Getting the $IPA_ADMIN_USER_NAME@$IPA_REALM user ID"
################################################################################
IPA_ADMIN_USER_ID=$( openstack --os-identity-api-version 3 \
                              --os-url ${SERVICE_ENDPOINT} \
                              --os-token ${SERVICE_TOKEN}  \
                              user show --domain $IPA_REALM $IPA_ADMIN_USER_NAME \
                                        -f value -c id  )
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          user show $IPA_ADMIN_USER_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Making $IPA_ADMIN_USER_NAME@$IPA_REALM the admin of the $IPA_REALM domain"
################################################################################
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role add --domain $IPA_REALM --user $IPA_ADMIN_USER_ID admin
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role add --domain $IPA_REALM --user $IPA_ADMIN_USER_ID user
openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN}  \
          role assignment list --domain $IPA_REALM --user $IPA_ADMIN_USER_ID



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring at the "$DEMO_PROJECT_NAME" project exists in the $IPA_REALM domain"
################################################################################
DEMO_PROJECT_DESCRIPTION="${OS_DISTRO}: Default Project"
IPA_DOMAIN_ID=$( openstack --os-identity-api-version 3 \
                          --os-url ${SERVICE_ENDPOINT} \
                          --os-token ${SERVICE_TOKEN}  \
                          domain show -f value -c id $IPA_REALM )

openstack --os-identity-api-version 3 \
          --os-url ${SERVICE_ENDPOINT} \
          --os-token ${SERVICE_TOKEN} \
          project create --or-show \
                  --domain ${IPA_DOMAIN_ID} \
                  --description "${DEMO_PROJECT_DESCRIPTION}" \
                  ${DEMO_PROJECT_NAME}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Ensuring that $IPA_ADMIN_USER_ID@$IPA_REALM is admin and member of the "$DEMO_PROJECT_NAME@$IPA_REALM" project"
################################################################################
DEMO_PROJECT_ID=$( openstack --os-identity-api-version 3 \
                            --os-url ${SERVICE_ENDPOINT} \
                            --os-token ${SERVICE_TOKEN}  \
                            project show $DEMO_PROJECT_NAME --domain $IPA_DOMAIN_ID -f value -c id )


ROLE="admin"
(
  openstack --os-identity-api-version 3 \
            --os-url ${SERVICE_ENDPOINT} \
            --os-token ${SERVICE_TOKEN} \
            role add --project $DEMO_PROJECT_ID \
                  --user $IPA_ADMIN_USER_ID \
                  ${ROLE} \
      || openstack --os-identity-api-version 3 \
                  --os-url ${SERVICE_ENDPOINT} \
                  --os-token ${SERVICE_TOKEN}  \
                  role assignment list --project $DEMO_PROJECT_ID --user $IPA_ADMIN_USER_ID
)
ROLE="user"
(
  openstack --os-identity-api-version 3 \
            --os-url ${SERVICE_ENDPOINT} \
            --os-token ${SERVICE_TOKEN} \
            role add --project $DEMO_PROJECT_ID \
                  --user $IPA_ADMIN_USER_ID \
                  ${ROLE} \
      || openstack --os-identity-api-version 3 \
                  --os-url ${SERVICE_ENDPOINT} \
                  --os-token ${SERVICE_TOKEN}  \
                  role assignment list --project $DEMO_PROJECT_ID --user $IPA_ADMIN_USER_ID
)
ROLE="heat_stack_owner"
(
  openstack --os-identity-api-version 3 \
            --os-url ${SERVICE_ENDPOINT} \
            --os-token ${SERVICE_TOKEN} \
            role add  --project $DEMO_PROJECT_ID \
                  --user $IPA_ADMIN_USER_ID \
                  ${ROLE} \
      || openstack --os-identity-api-version 3 \
                  --os-url ${SERVICE_ENDPOINT} \
                  --os-token ${SERVICE_TOKEN}  \
                  role assignment list --project $DEMO_PROJECT_ID --user $IPA_ADMIN_USER_ID
)
openstack --os-identity-api-version 3 \
                --os-url ${SERVICE_ENDPOINT} \
                --os-token ${SERVICE_TOKEN}  \
                role assignment list --project $DEMO_PROJECT_ID --user $IPA_ADMIN_USER_ID


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Generating openrc file for ${IPA_ADMIN_USER_NAME}@${IPA_REALM}"
################################################################################
cat > /openrc_${IPA_ADMIN_USER_NAME}-${IPA_REALM} << EOF
export OS_USERNAME=${IPA_ADMIN_USER_NAME}
export OS_PASSWORD=${IPA_USER_ADMIN_PASSWORD}
#export OS_DOMAIN_NAME=$IPA_REALM
export OS_PROJECT_NAME=${DEMO_PROJECT_NAME}
export OS_TENANT_NAME="$OS_PROJECT_NAME"
export OS_USER_DOMAIN_NAME=${IPA_REALM}
export OS_PROJECT_DOMAIN_NAME=${IPA_REALM}
export OS_AUTH_URL=$SERVICE_ENDPOINT
export OS_IDENTITY_API_VERSION=3
export PS1="[(\$IPA_ADMIN_USER_NAME@\${OS_PROJECT_DOMAIN_NAME}:\${OS_PROJECT_NAME}) \\u@\\h \\W] ⌘ "
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring to make the ${IPA_DOMAIN_ID} the default for v2 requests"
################################################################################
IPA_DOMAIN_ID=$( openstack --os-identity-api-version 3 \
                  --os-url ${SERVICE_ENDPOINT} \
                  --os-token ${SERVICE_TOKEN}  \
                  domain show -f value -c id $IPA_REALM )

crudini --set $cfg identity default_domain_id "${IPA_DOMAIN_ID}"

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** DUMPING LOGS OF BOOTSTRAP SERVER ***"
################################################################################
mkdir -p /var/log/apache2
touch /var/log/apache2/keystone_access.log
cat /var/log/apache2/keystone_access.log

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: *** RESTARTING ***"
################################################################################
httpd -k restart

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Verifying Keystone is running"
################################################################################
while ! curl -o /dev/null -s --fail ${SERVICE_ENDPOINT}; do
    echo "${OS_DISTRO}: Waiting for Keystone @ ${SERVICE_ENDPOINT}"
    sleep 1;
done

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking that ${IPA_ADMIN_USER_NAME}@${IPA_REALM} can get a token from keystone"
################################################################################
source /openrc_${IPA_ADMIN_USER_NAME}-${IPA_REALM}
openstack token issue



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Sending Default Domain ID to ETCD"
################################################################################
etcdctl --endpoint ${ETCDCTL_ENDPOINT} set /${OS_DISTRO}/${OPENSTACK_COMPONENT}/default_domain_id ${IPA_DOMAIN_ID}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configured"
################################################################################
httpd -k stop
