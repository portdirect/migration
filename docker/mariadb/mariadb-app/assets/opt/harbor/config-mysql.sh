#!/bin/bash
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

################################################################################
echo "${OS_DISTRO}: Running Common Config Script"
################################################################################
. /opt/harbor/harbor-common.sh

: ${BIND_ADDRESS:=$PUBLIC_IP}
: ${DB_ROOT_PASSWORD:=$DB_ROOT_PASSWORD}
: ${DEFAULT_STORAGE_ENGINE:=innodb}
: ${COLLATION_SERVER:=utf8_general_ci}
: ${INIT_CONNECT:=SET NAMES utf8}
: ${CHAR_SET_SERVER:=utf8}
: ${INNODB_FILE_PER_TABLE:=true}
: ${MAX_CONNECTIONS:="1000"}
: ${DATADIR:=/var/lib/mysql}
: ${TEMP_FILE:='/tmp/mysql-first-time.sql'}


################################################################################
echo "${OS_DISTRO}: Configuring MySQL server"
################################################################################
server_cnf=/etc/my.cnf.d/server.cnf

# As we are running in a container docker will manage the bindings for us and we should listen on all ports
BIND_ADDRESS=0.0.0.0

crudini --set $server_cnf mysqld bind-address $BIND_ADDRESS
crudini --set $server_cnf mysqld max_connections "$MAX_CONNECTIONS"
crudini --set $server_cnf mysqld default-storage-engine $DEFAULT_STORAGE_ENGINE
crudini --set $server_cnf mysqld collation-server $COLLATION_SERVER
crudini --set $server_cnf mysqld init-connect "'${INIT_CONNECT}'"
crudini --set $server_cnf mysqld character-set-server $CHAR_SET_SERVER
if [ "${INNODB_FILE_PER_TABLE}" == "true" ] || ["${INNODB_FILE_PER_TABLE}" == "True" ] ; then
  crudini --set $server_cnf mysqld innodb_file_per_table 1
fi

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' | sed 's/\\r$//g'  > /etc/pki/tls/certs/ca.crt
cat /etc/os-ssl/ca | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/certs/ca-auth.crt
crudini --set $server_cnf mysqld ssl-ca "/etc/pki/tls/certs/ca-auth.crt"
crudini --set $server_cnf mysqld ssl-cert "/etc/pki/tls/certs/ca.crt"
crudini --set $server_cnf mysqld ssl-key "/etc/pki/tls/private/ca.key"
crudini --set $server_cnf mysqld ssl-cipher "TLSv1.2"
