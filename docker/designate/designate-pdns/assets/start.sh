#!/bin/bash
set -o errexit
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
. /opt/harbor/designate/common-vars.sh
: ${DEFAULT_REGION:="HarborOS"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars MARIADB_SERVICE_HOST DESIGNATE_PDNS_DB_USER DESIGNATE_PDNS_DB_PASSWORD \
                    DESIGNATE_PDNS_DB_NAME


: ${DESIGNATE_DNS_SERVICE_HOSTNAME:="designate-dns.os-designate.svc.$OS_DOMAIN"}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking That this host has a IP correctly assigned via kubernetes"
################################################################################
n=0
until [ $n -ge 36 ]
do
  if [[ $(dig +short designate-dns.os-designate.svc.$OS_DOMAIN | head -n1) ]]; then
      echo "Kube is returning an IP" && break
  fi
   n=$[$n+1]
   ################################################################################
   echo "${OS_DISTRO}: Waiting for Kube attempt $n of 36"
   ################################################################################
   sleep 5
done
DESIGNATE_DNS_SERVICE_SVC_IP="$(dig +short designate-dns.os-designate.svc.$OS_DOMAIN | head -n1)"
ip -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $2" "$4}' | grep ${DESIGNATE_DNS_SERVICE_SVC_IP} || ( echo "This node has not got an ip address that kubernetes is aware of" && exit 1 )


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Enviornment Variables"
################################################################################
check_required_vars DESIGNATE_DNS_SERVICE_SVC_IP DESIGNATE_PDNS_DB_NAME \
                    MARIADB_SERVICE_HOST DESIGNATE_PDNS_DB_USER DESIGNATE_PDNS_DB_PASSWORD


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_db ${DESIGNATE_PDNS_DB_NAME}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up pdns Conf"
################################################################################
cat > /etc/pdns/pdns.conf <<EOF
# General Config
setgid=pdns
setuid=pdns
config-dir=/etc/pdns
socket-dir=/var/run
guardian=yes
daemon=no
disable-axfr=no
local-address=${DESIGNATE_DNS_SERVICE_SVC_IP}
local-port=553
master=no
slave=yes
cache-ttl=0
query-cache-ttl=0
negquery-cache-ttl=0
out-of-zone-additional-processing=no

# Launch gmysql backend
launch=gmysql

# gmysql parameters
gmysql-host=${MARIADB_SERVICE_HOST}
gmysql-user=${DESIGNATE_PDNS_DB_USER}
gmysql-password=${DESIGNATE_PDNS_DB_PASSWORD}
gmysql-dbname=${DESIGNATE_PDNS_DB_NAME}
gmysql-dnssec=yes
EOF


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Starting PDNS"
################################################################################
exec /usr/sbin/pdns_server
