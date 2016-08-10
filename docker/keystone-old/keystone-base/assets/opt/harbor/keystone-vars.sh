#!/bin/bash
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Common Vars"
################################################################################
. /opt/harbor/service_hosts.sh

# Credentials, token, etc..
: ${SERVICES_TENANT_NAME:="services"}
# Service Addresses/Ports/Version
: ${KEYSTONE_PUBLIC_SERVICE_PORT:=5000}
: ${KEYSTONE_ADMIN_SERVICE_PORT:=35357}
: ${KEYSTONE_API_VERSION:="3"}
# Logging
: ${LOG_FILE:="/var/log/keystone/keystone.log"}
: ${VERBOSE_LOGGING:=True}
: ${DEBUG_LOGGING:=True}
: ${USE_STDERR:=false}
# Token provider, driver, etc..
: ${TOKEN_PROVIDER:=uuid}
: ${TOKEN_DRIVER:=sql}
# Domains
: ${DEFAULT_REGION:="HarborOS"}
: ${BRANDING_DOMAIN:=$OS_DOMAIN}

: ${IPA_ADMIN_USER_NAME:="admin"}
: ${DEMO_PROJECT_NAME:="$OS_DOMAIN"}
