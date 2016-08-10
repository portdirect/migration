#!/bin/bash
set -e
OPENSTACK_SUBCOMPONENT=database
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}"
################################################################################
source /etc/os-container.env
. /opt/harbor/service_hosts.sh
. /opt/harbor/harbor-common.sh


: ${MARIADB_CA:="/etc/os-ssl-database/database-ca.crt"}
: ${MARIADB_KEY:="/etc/os-ssl-database/database.key"}
: ${MARIADB_CIRT:="/etc/os-ssl-database/database.crt"}
: ${HORIZON_DB_CA:="${MARIADB_CA}"}
: ${HORIZON_DB_KEY:="${MARIADB_KEY}"}
: ${HORIZON_DB_CIRT:="${MARIADB_CIRT}"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars cfg MARIADB_SERVICE_HOST \
                        HORIZON_DB_USER HORIZON_DB_PASSWORD HORIZON_DB_NAME \
                        HORIZON_DB_CA HORIZON_DB_KEY HORIZON_DB_CIRT


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Configuring DB Cache"
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
        'default-character-set': 'utf8',
        'PORT': '3306',
        'OPTIONS':  {
                  'ssl': {'ca': '${HORIZON_DB_CA}',
                          'cert': '${HORIZON_DB_CIRT}',
                          'key': '${HORIZON_DB_KEY}',
                          'read_default_file': '/etc/horizon/mysql.cfg',
                          }
                    }
    }
}

SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'

EOF

SNIPPET_INSERT_POINT="# memcached set CACHES to something like"
SNIPPET_END_POINT="# Send email to the console by default"
sed -i -ne "/${SNIPPET_INSERT_POINT}/ {p; r /etc/openstack-dashboard/cache-snippet" -e ":a; n; /${SNIPPET_END_POINT}/ {p; b}; ba}; p" $cfg
rm -rf /etc/openstack-dashboard/cache-snippet

mkdir -p /etc/horizon
cat > /etc/horizon/mysql.cfg <<EOF
[client]
ssl-mode=VERIFY_IDENTITY
EOF
