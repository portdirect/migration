#!/bin/sh
set -e

###############################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Adapting vars from base image"
################################################################################
RABBITMQ_USER="guest"
RABBITMQ_PASS="guest"

################################################################################
echo "${OS_DISTRO}: RabbitMQ: Starting"
################################################################################
: ${RABBITMQ_NODENAME:="messaging"}
: ${RABBITMQ_LOG_BASE:=/var/log/rabbitmq}

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

echo "127.0.0.1 $(hostname)" >> /etc/hosts

################################################################################
echo "${OS_DISTRO}: RabbitMQ: Launching"
################################################################################
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq
mkdir -p /var/log/rabbitmq
chown -R rabbitmq:rabbitmq /var/log/rabbitmq
exec su -s /bin/sh -c "exec rabbitmq-server" rabbitmq
