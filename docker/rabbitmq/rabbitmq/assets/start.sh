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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking ENV"
################################################################################
check_required_vars RABBITMQ_USER RABBITMQ_PASS

################################################################################
echo "${OS_DISTRO}: RabbitMQ: Starting"
################################################################################
: ${RABBITMQ_NODENAME:="messaging"}
: ${RABBITMQ_LOG_BASE:=/var/log/rabbitmq}


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: TLS"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
cat /etc/os-ssl/key | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/private/ca.key
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' | sed 's/\\r$//g'  > /etc/pki/tls/certs/ca.crt
cat /etc/os-ssl/ca | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/pki/tls/certs/ca-auth.crt



################################################################################
echo "${OS_DISTRO}: RabbitMQ: Configuring"
################################################################################
sed -i '
	s|@RABBITMQ_USER@|'"$RABBITMQ_USER"'|g
	s|@RABBITMQ_PASS@|'"$RABBITMQ_PASS"'|g
' /etc/rabbitmq/rabbitmq.config

sed -i '
	s|@RABBITMQ_NODENAME@|'"$RABBITMQ_NODENAME"'|g
	s|@RABBITMQ_LOG_BASE@|'"$RABBITMQ_LOG_BASE"'|g
' /etc/rabbitmq/rabbitmq-env.conf

#echo "127.0.0.1 $(hostname --short)" >> /etc/hosts


################################################################################
echo "${OS_DISTRO}: RabbitMQ: Launching"
################################################################################
exec su -s /bin/sh rabbitmq /usr/sbin/rabbitmq-server
