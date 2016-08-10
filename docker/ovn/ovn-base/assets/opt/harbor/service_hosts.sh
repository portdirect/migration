#!/bin/bash



: ${OS_DOMAIN:="kube.local"}

# ECTD Settings
: ${ETCDCTL_ENDPOINT:="http://etcd.os-etcd.svc.${OS_DOMAIN}:4001"}

# DB Settings
: ${MARIADB_HOSTNAME:="database"}
: ${MARIADB_SERVICE_HOST:="${MARIADB_HOSTNAME}.$OS_DOMAIN"}
: ${MONGODB_HOSTNAME:="mongodb"}
: ${MONGODB_SERVICE_HOST:="${MONGODB_HOSTNAME}.$OS_DOMAIN"}
# Messaging Settings
: ${RABBITMQ_HOSTNAME:="messaging"}
: ${RABBITMQ_SERVICE_HOST:="${RABBITMQ_HOSTNAME}.$OS_DOMAIN"}
# Keystone Settings
: ${KEYSTONE_ADMIN_SERVICE_HOSTNAME:="keystone"}
: ${KEYSTONE_ADMIN_SERVICE_HOST:="${KEYSTONE_ADMIN_SERVICE_HOSTNAME}.$OS_DOMAIN"}
: ${KEYSTONE_PUBLIC_SERVICE_HOSTNAME:="keystone"}
: ${KEYSTONE_PUBLIC_SERVICE_HOST:="${KEYSTONE_PUBLIC_SERVICE_HOSTNAME}.$OS_DOMAIN"}
: ${KEYSTONE_OLD_ADMIN_SERVICE_HOSTNAME:="keystone-v2"}
: ${KEYSTONE_OLD_ADMIN_SERVICE_HOST:="${KEYSTONE_OLD_ADMIN_SERVICE_HOSTNAME}.$OS_DOMAIN"}
: ${KEYSTONE_OLD_PUBLIC_SERVICE_HOSTNAME:="keystone-v2"}
: ${KEYSTONE_OLD_PUBLIC_SERVICE_HOST:="${KEYSTONE_OLD_PUBLIC_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Glance Settings
: ${GLANCE_API_SERVICE_HOSTNAME:="glance"}
: ${GLANCE_API_SERVICE_HOST:="${GLANCE_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
: ${GLANCE_REGISTRY_SERVICE_HOSTNAME:="glance-registry"}
: ${GLANCE_REGISTRY_SERVICE_HOST:="${GLANCE_REGISTRY_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Nova Settings
: ${NOVA_API_SERVICE_HOSTNAME:="nova"}
: ${NOVA_API_SERVICE_HOST:="${NOVA_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Neutron Settings
: ${NEUTRON_API_SERVICE_HOSTNAME:="neutron"}
: ${NEUTRON_API_SERVICE_HOST:="${NEUTRON_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Swift Settings
: ${SWIFT_API_SERVICE_HOSTNAME:="swift"}
: ${SWIFT_API_SERVICE_HOST:="${SWIFT_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Cinder Settings
: ${CINDER_API_SERVICE_HOSTNAME:="cinder"}
: ${CINDER_API_SERVICE_HOST:="${CINDER_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Heat Settings
: ${HEAT_API_SERVICE_HOSTNAME:="heat"}
: ${HEAT_API_SERVICE_HOST:="${HEAT_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Heat CFN Settings
: ${HEAT_API_CFN_SERVICE_HOSTNAME:="heat-cfn"}
: ${HEAT_API_CFN_SERVICE_HOST:="${HEAT_API_CFN_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Heat CloudWatch Settings
: ${HEAT_API_CLOUDWATCH_SERVICE_HOSTNAME:="heat-cloudwatch"}
: ${HEAT_API_CLOUDWATCH_SERVICE_HOST:="${HEAT_API_CLOUDWATCH_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Murano Settings
: ${MURANO_API_SERVICE_HOSTNAME:="murano"}
: ${MURANO_API_SERVICE_HOST:="${MURANO_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Sahara Settings
: ${SAHARA_API_SERVICE_HOSTNAME:="sahara"}
: ${SAHARA_API_SERVICE_HOST:="${SAHARA_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Ceilometer Settings
: ${CEILOMETER_API_SERVICE_HOSTNAME:="ceilometer"}
: ${CEILOMETER_API_SERVICE_HOST:="${CEILOMETER_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Gnocchi Settings
: ${GNOCCHI_API_SERVICE_HOSTNAME:="gnocchi"}
: ${GNOCCHI_API_SERVICE_HOST:="${GNOCCHI_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Magnum Settings
: ${MAGNUM_API_SERVICE_HOSTNAME:="magnum"}
: ${MAGNUM_API_SERVICE_HOST:="${MAGNUM_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Barbican Settings
: ${BARBICAN_API_SERVICE_HOSTNAME:="barbican"}
: ${BARBICAN_API_SERVICE_HOST:="${BARBICAN_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Trove Settings
: ${TROVE_API_SERVICE_HOSTNAME:="trove"}
: ${TROVE_API_SERVICE_HOST:="${TROVE_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Manila Settings
: ${MANILA_API_SERVICE_HOSTNAME:="manila"}
: ${MANILA_API_SERVICE_HOST:="${MANILA_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}
# Designate Settings
: ${DESIGNATE_API_SERVICE_HOSTNAME:="designate"}
: ${DESIGNATE_API_SERVICE_HOST:="${DESIGNATE_API_SERVICE_HOSTNAME}.$OS_DOMAIN"}



: ${KEYSTONE_AUTH_PROTOCOL:="https"}
: ${KEYSTONE_PUBLIC_SERVICE_PORT:="443"}
: ${KEYSTONE_ADMIN_SERVICE_PORT:="35357"}
: ${SERVICE_TENANT_NAME:="services"}
: ${ADMIN_USER:="admin"}
: ${ADMIN_USER_DOMAIN:="default"}
: ${ADMIN_USER_PROJECT_DOMAIN:="default"}
: ${DEFAULT_REGION:="HarborOS"}
: ${DEBUG:="False"}