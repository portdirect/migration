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

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars HORIZON_DB_NAME HORIZON_DB_USER HORIZON_DB_PASSWORD MARIADB_SERVICE_HOST \
                    KEYSTONE_ADMIN_SERVICE_HOST

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${HORIZON_DB_NAME}
fail_unless_os_service_running keystone

#fail_unless_os_service_running keystone
#fail_unless_os_service_running glance
#fail_unless_os_service_running nova



################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSL"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt
/opt/horizon/manage.py make_web_conf --apache --ssl > /etc/httpd/conf.d/horizon.conf

cat >> /etc/httpd/conf.d/horizon.conf <<EOF
<VirtualHost *:80>
  ServerName ${HOST}
  ServerAlias api
  RewriteEngine on
  RewriteRule ^/(.*)\$ https://${HOST}/\$1
</VirtualHost>
EOF

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting for our Cirts"
################################################################################
while [ ! -f "/etc/pki/tls/private/ca.key" ]; # true if /your/file does not exist
do
  sleep 1
done
while [ ! -f "/etc/pki/tls/certs/ca.crt" ]; # true if /your/file does not exist
do
  sleep 1
done


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Defining Endpoints"
################################################################################
export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v3"



cfg=/etc/openstack-dashboard/local_settings
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Encoding"
################################################################################
#sed -i '1i# encoding: utf-8' $cfg

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Allowed Hosts"
################################################################################
sed -i "s/horizon.example.com/*/g" $cfg

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Keystone"
################################################################################
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${KEYSTONE_ADMIN_SERVICE_HOST}\"/g" $cfg
sed -i "s,OPENSTACK_KEYSTONE_URL = \"http://%s:5000/v3\" % OPENSTACK_HOST,OPENSTACK_KEYSTONE_URL = \"${KEYSTONE_AUTH_PROTOCOL}://%s:5000/v3\" % OPENSTACK_HOST,g" $cfg
sed -i "s/#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g" $cfg
sed -i "s/#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = \"$OS_DOMAIN\"/g" $cfg
sed -i "s/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"_member_\"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"/g" $cfg

sed -i "s,WEBROOT = '/dashboard/',WEBROOT = '/',g" $cfg
sed -i "s,DEBUG = False,DEBUG = True,g" $cfg

#sed -i "s,#CUSTOM_THEME_PATH = 'themes/default',CUSTOM_THEME_PATH = 'themes/harbor',g" /etc/openstack-dashboard/local_settings
#sed -i "s,#DISALLOW_IFRAME_EMBED = True,DISALLOW_IFRAME_EMBED = False,g" $cfg


sed -i "s/'name': 'native'/'name': 'ldap'/g" $cfg
sed -i "s/'can_edit_user': True/'can_edit_user': False/g" $cfg


sed -i "s/#LAUNCH_INSTANCE_LEGACY_ENABLED = True/LAUNCH_INSTANCE_LEGACY_ENABLED = False/g" $cfg
sed -i "s/#LAUNCH_INSTANCE_NG_ENABLED = False/LAUNCH_INSTANCE_NG_ENABLED = True/g" $cfg



sed -i "s/#CSRF_COOKIE_SECURE = True/CSRF_COOKIE_SECURE = True/g" $cfg
sed -i "s/#SESSION_COOKIE_SECURE = True/SESSION_COOKIE_SECURE = True/g" $cfg


sed -i 's/#CONSOLE_TYPE = "AUTO"/CONSOLE_TYPE = "SPICE"/g' $cfg








################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Cache"
################################################################################
cat > /etc/openstack-dashboard/cache-snippet  <<EOF
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
    }
}

DATABASES = {
    'default': {
        # Database configuration here
        'ENGINE': 'django.db.backends.mysql',
        'NAME': '${HORIZON_DB_NAME}',
        'USER': '${HORIZON_DB_USER}',
        'PASSWORD': '${HORIZON_DB_PASSWORD}',
        'HOST': '${MARIADB_SERVICE_HOST}',
        'default-character-set': 'utf8'
    }
}

SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'

EOF

SNIPPET_INSERT_POINT="# memcached set CACHES to something like"
SNIPPET_END_POINT="# Send email to the console by default"
sed -i -ne "/${SNIPPET_INSERT_POINT}/ {p; r /etc/openstack-dashboard/cache-snippet" -e ":a; n; /${SNIPPET_END_POINT}/ {p; b}; ba}; p" $cfg
rm -rf /etc/openstack-dashboard/cache-snippet


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: API Versions"
################################################################################
cat >> $cfg <<EOF
OPENSTACK_API_VERSIONS = {
    "data-processing": 1.1,
    "identity": 3,
    "volume": 2,
    "image": 2,
}
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Cinder Backup"
################################################################################
sed -i "s/'enable_backup': False,/'enable_backup': True,/g" $cfg




# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Horizon"
# ################################################################################
# cat >> $cfg <<EOF
# HORIZON_CONFIG = {
#     'user_home': '/harbor',
#     'ajax_queue_limit': 10,
#     'auto_fade_alerts': {
#         'delay': 3000,
#         'fade_duration': 1500,
#         'types': ['alert-success', 'alert-info']
#     },
#     'bug_url': None,
#     'help_url': "http://docs.$(hostname --domain)/user-guide",
#     'exceptions': {'recoverable': exceptions.RECOVERABLE,
#                    'not_found': exceptions.NOT_FOUND,
#                    'unauthorized': exceptions.UNAUTHORIZED},
#     'modal_backdrop': 'static',
#     'angular_modules': [],
#     'js_files': ['custom/js/bootstrap-window.js', 'custom/js/gridster.js', 'custom/js/content-area.js', 'custom/js/jquery.scrollTo.js'],
#     'js_spec_files': [],
#     'external_templates': [],
# }
# EOF

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Config: Branding"
################################################################################
echo "SITE_BRANDING = \"$OS_DOMAIN\"" >> $cfg





# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Collecting Static Files"
# ################################################################################
# /opt/horizon/manage.py collectstatic --noinput
# #
# #
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Compressing Assets"
################################################################################
/opt/horizon/manage.py compress

################################################################################
#echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Starting Dev server"
################################################################################
#/opt/horizon/manage.py runserver 0.0.0.0:80


#
################################################################################
#echo "${OS_DISTRO}: ${OcPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: APACHE: Config"
################################################################################
#/opt/horizon/manage.py  make_web_conf --wsgi
#/usr/bin/manage.py make_web_conf --apache --hostname=$(hostname --fqdn) > /etc/httpd/conf.d/horizon.conf
#rm -rf /etc/httpd/conf.d/*
#/opt/horizon/manage.py make_web_conf --apache > /etc/httpd/conf.d/horizon.conf
#
#
# ################################################################################
# echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: APACHE: Permissions"
# ################################################################################
#chown -R apache:horizon /usr/lib/python2.7/site-packages/openstack_dashboard


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: APACHE: Launching"
################################################################################

httpd -DFOREGROUND
