#!/bin/sh
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
. /opt/harbor/harbor-common.sh


export cfg=/etc/grafana/grafana.ini
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: WEBSERVER"
################################################################################
crudini --set $cfg server protocol "http"
crudini --set $cfg server http_addr "127.0.0.1"
crudini --set $cfg server http_port "3001"
crudini --set $cfg server domain "grafana.${OS_DOMAIN}"
crudini --set $cfg server enforce_domain "true"
crudini --set $cfg server root_url "https://%(domain)s/grafana"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: AUTH"
################################################################################
crudini --set $cfg auth.proxy enabled "true"
crudini --set $cfg auth.proxy header_name "X-WEBAUTH-USER"
crudini --set $cfg auth.proxy header_property "username"
crudini --set $cfg auth.proxy auto_sign_up "false"
crudini --set $cfg auth.basic enabled "false"
crudini --set $cfg auth.ldap enabled "true"
crudini --set $cfg auth.ldap config_file "/etc/grafana/ldap.toml"



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LDAP"
################################################################################
export IPA_SERVER=$(cat /etc/ipa/default.conf | grep "server" | awk '{print $3}')
export IPA_REALM=$(cat /etc/ipa/default.conf | grep "realm" | awk '{print $3}')
export IPA_BASE_DN=$( cat /etc/openldap/ldap.conf | grep "^BASE " | awk '{print $2}' )
export IPA_URI=$( cat /etc/openldap/ldap.conf | grep "^URI " | awk '{print $2}' )
export IPA_LDAP_CRT=$( cat /etc/openldap/ldap.conf | grep "^TLS_CACERT " | awk '{print $2}' )
export GRAFANA_LDAP_BIND_DN="uid=${GRAFANA_LDAP_USER},cn=users,cn=accounts,$IPA_BASE_DN"

cat > /etc/grafana/ldap.toml <<EOF
# Set to true to log user information returned from LDAP
verbose_logging = true

[[servers]]
# Ldap server host (specify multiple hosts space separated)
host = "${IPA_SERVER}"
# Default port is 389 or 636 if use_ssl = true
port = 636
# Set to true if ldap server supports TLS
use_ssl = true
# set to true if you want to skip ssl cert validation
ssl_skip_verify = false
# set to the path to your root CA certificate or leave unset to use system defaults
root_ca_cert = "${IPA_LDAP_CRT}"

# Search user bind dn
bind_dn = "${GRAFANA_LDAP_BIND_DN}"
# Search user bind password
bind_password = '${GRAFANA_LDAP_PASSWORD}'

# User search filter, for example "(cn=%s)" or "(sAMAccountName=%s)" or "(uid=%s)"
search_filter = "(uid=%s)"

# An array of base dns to search through
search_base_dns = ["cn=users,cn=accounts,${IPA_BASE_DN}"]

# In POSIX LDAP schemas, without memberOf attribute a secondary query must be made for groups.
# This is done by enabling group_search_filter below. You must also set member_of= "cn"
# in [servers.attributes] below.

## Group search filter, to retrieve the groups of which the user is a member (only set if memberOf attribute is not available)
# group_search_filter = "(&(objectClass=posixGroup)(memberUid=%s))"
## An array of the base DNs to search through for groups. Typically uses ou=groups
group_search_base_dns = ["cn=groups,cn=accounts,$IPA_BASE_DN"]

# Specify names of the ldap attributes your ldap uses
[servers.attributes]
name = "givenName"
surname = "sn"
username = "uid"
member_of = "memberOf"
email =  "mail"

# Map ldap groups to grafana org roles
[[servers.group_mappings]]
group_dn = "cn=admins,cn=groups,cn=accounts,$IPA_BASE_DN"
org_role = "Admin"
# The Grafana organization database id, optional, if left out the default org (id 1) will be used
# org_id = 1

# [[servers.group_mappings]]
# group_dn = "cn=ipausers,cn=groups,cn=accounts,$IPA_BASE_DN"
# org_role = "Editor"

[[servers.group_mappings]]
# If you want to match all (or no ldap groups) then you can use wildcard
group_dn = "*"
org_role = "Viewer"
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: DATABASE"
################################################################################
crudini --set $cfg database type "mysql"
crudini --set $cfg database host "${MARIADB_SERVICE_HOST}:3306"
crudini --set $cfg database name "${GRAFANA_DB_NAME}"
crudini --set $cfg database user "${GRAFANA_DB_USER}"
crudini --set $cfg database password "${GRAFANA_DB_PASSWORD}"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: EMAIL"
################################################################################
crudini --set $cfg smtp enabled "true"
crudini --set $cfg smtp host "${GRAFANA_SMTP_HOST}:${GRAFANA_SMTP_PORT}"
crudini --set $cfg smtp user "${GRAFANA_SMTP_USER}"
crudini --set $cfg smtp password "${GRAFANA_SMTP_PASS}"
crudini --set $cfg smtp from_address "${GRAFANA_DEFAULT_ADMIN_EMAIL}"
crudini --set $cfg emails welcome_email_on_sign_up "true"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: LOGGING"
################################################################################
crudini --set $cfg log mode "console"
crudini --set $cfg log level "Info"
crudini --set $cfg log.console level "Info"
crudini --set $cfg analytics reporting_enabled "false"


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Security"
################################################################################
crudini --set $cfg security admin_user "admin"
# Fill the admin password with a junk value as we get users from ldap
crudini --set $cfg security admin_password "$(uuidgen -r | tr -d '-')"
crudini --set $cfg security secret_key "${GRAFANA_SECRET_KEY}"
crudini --set $cfg security login_remember_days '1'
crudini --set $cfg security cookie_username "grafana_user"
crudini --set $cfg security cookie_remember_name "grafana_remember"
crudini --set $cfg security disable_gravatar "true"
# data source proxy whitelist (ip_or_domain:port seperated by spaces)
#crudini --set $cfg security data_source_proxy_whitelist ""


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching"
################################################################################
chown -R grafana /usr/share/grafana
exec su -s /bin/sh -c "exec /usr/sbin/grafana-server --config=/etc/grafana/grafana.ini --homepath=/usr/share/grafana" grafana
