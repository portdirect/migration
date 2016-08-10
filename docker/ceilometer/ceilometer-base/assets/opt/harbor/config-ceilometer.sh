#!/bin/sh
set -e
OPENSTACK_SUBCOMPONENT=common-config
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
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Checking Env"
################################################################################



export cfg=/etc/ceilometer/ceilometer.conf
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: COMPONENTS"
################################################################################
. /opt/harbor/ceilometer/config-rabbitmq.sh
. /opt/harbor/ceilometer/config-keystone.sh
. /opt/harbor/ceilometer/config-database.sh
. /opt/harbor/ceilometer/config-gnocchi.sh


#
# Options defined in ceilometer.utils
#

# Path to the rootwrap configuration file touse for running
# commands as root (string value)
crudini --set $cfg DEFAULT rootwrap_config "/etc/ceilometer/rootwrap.conf"




#
# Options defined in ceilometer.openstack.common.log
#

# Print debugging output (set logging level to DEBUG instead
# of default WARNING level). (boolean value)
#debug=false

# Print more verbose output (set logging level to INFO instead
# of default WARNING level). (boolean value)
#verbose=false

# Log output to standard error. (boolean value)
crudini --set $cfg DEFAULT use_stderr "true"


#[api]

#
# Options defined in ceilometer.api
#

# The port for the ceilometer API server. (integer value)
# Deprecated group/name - [DEFAULT]/metering_api_port
crudini --set $cfg api port "8777"

# The listen IP for the ceilometer API server. (string value)
crudini --set $cfg api  host "0.0.0.0"

# Set it to False if your environment does not need or have
# dns server, otherwise it will delay the response from api.
# (boolean value)
crudini --set $cfg api enable_reverse_dns_lookup "true"


#[collector]

#
# Options defined in ceilometer.collector
#

# Address to which the UDP socket is bound. Set to an empty
# string to disable. (string value)
crudini --set $cfg collector udp_address "0.0.0.0"

# Port to which the UDP socket is bound. (integer value)
crudini --set $cfg collector udp_port "4952"

# Requeue the sample on the collector sample queue when the
# collector fails to dispatch it. This is only valid if the
# sample come from the notifier publisher (boolean value)
#requeue_sample_on_dispatcher_error=false


#[publisher]

#
# Options defined in ceilometer.publisher.utils
#

# Secret value for signing metering messages. (string value)
# Deprecated group/name - [DEFAULT]/metering_secret
# Deprecated group/name - [publisher_rpc]/metering_secret
crudini --set $cfg publisher metering_secret "${CEILOMETER_METERING_SECRET}"
