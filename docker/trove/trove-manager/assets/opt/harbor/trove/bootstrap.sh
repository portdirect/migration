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
check_required_vars TROVE_KEYSTONE_USER TROVE_KEYSTONE_PASSWORD


################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Checking Service Dependencies"
################################################################################
fail_unless_os_service_running keystone

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting API to become active"
################################################################################
source /openrc

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Launching Bootstraper"
################################################################################

    ################################################################################
    echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Creating inital volume type"
    ################################################################################
    export DATASTORE_TYPE="mysql" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    export DATASTORE_VERSION="5.6" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    export PACKAGES="rh-mysql56-mysql-server" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    trove-manage datastore_update ${DATASTORE_TYPE} ""
    trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}

    export DATASTORE_TYPE="mariadb" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    export DATASTORE_VERSION="10.1" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    export PACKAGES="mariadb-server" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    trove-manage datastore_update ${DATASTORE_TYPE} ""
    trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}

    export DATASTORE_TYPE="mongodb" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    export DATASTORE_VERSION="2.6.11" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    export PACKAGES="mongodb-server" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    trove-manage datastore_update ${DATASTORE_TYPE} ""
    trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}
    #
    # export DATASTORE_TYPE="redis" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    # export DATASTORE_VERSION="3.0.7" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    # export PACKAGES="redis=3.0.7" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    # export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    # openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    # trove-manage datastore_update ${DATASTORE_TYPE} ""
    # trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    # trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}
    #
    # export DATASTORE_TYPE="percona" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    # export DATASTORE_VERSION="5.6" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    # export PACKAGES="percona-server-server-5.6" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    # export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    # openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    # trove-manage datastore_update ${DATASTORE_TYPE} ""
    # trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    # trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}
    #
    # export DATASTORE_TYPE="postgresql" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    # export DATASTORE_VERSION="9.3" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    # export PACKAGES="postgresql-9.3" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    # export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    # openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    # trove-manage datastore_update ${DATASTORE_TYPE} ""
    # trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    # trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}
    #
    # export DATASTORE_TYPE="couchbase" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    # export DATASTORE_VERSION="2.2.0" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    # export PACKAGES="couchbase-server-community=2.2.0" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    # export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    # openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    # trove-manage datastore_update ${DATASTORE_TYPE} ""
    # trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    # trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}
    #
    # export DATASTORE_TYPE="couchdb" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    # export DATASTORE_VERSION="1.6.1" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    # export PACKAGES="couchdb=1.6.1" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    # export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    # openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    # trove-manage datastore_update ${DATASTORE_TYPE} ""
    # trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    # trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}
    #
    # export DATASTORE_TYPE="pxc" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    # export DATASTORE_VERSION="5.6" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    # export PACKAGES="percona-xtradb-cluster-server=5.6" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    # export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    # openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    # trove-manage datastore_update ${DATASTORE_TYPE} ""
    # trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    # trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}
    #
    # export DATASTORE_TYPE="cassandra" # available options: mysql, mongodb, postgresql, redis, cassandra, couchbase, couchdb, db2, vertica, etc.
    # export DATASTORE_VERSION="2.0.x" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
    # export PACKAGES="cassandra=2.1.*" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
    # export IMAGEID="$(etcdctl --endpoint ${ETCDCTL_ENDPOINT} get /${OS_DISTRO}/${OPENSTACK_COMPONENT}/${DATASTORE_TYPE}/image-id)" # Glance image ID of the relevant Datastore version (see Source images section)
    # openstack image set --property "sw_database_${DATASTORE_TYPE}_version=${DATASTORE_VERSION}" ${IMAGEID}
    # trove-manage datastore_update ${DATASTORE_TYPE} ""
    # trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
    # trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}

    MANILA_SERVICE_VM_FLAVOR_NAME=trove-small
    MANILA_SERVICE_VM_FLAVOR_REF=101
    MANILA_SERVICE_VM_FLAVOR_RAM=256
    MANILA_SERVICE_VM_FLAVOR_DISK=2
    MANILA_SERVICE_VM_FLAVOR_VCPUS=1
    MANILA_SERVICE_VM_FLAVOR_EPHEMERAL=2
    nova flavor-show $MANILA_SERVICE_VM_FLAVOR_NAME || nova flavor-create \
        --ephemeral ${MANILA_SERVICE_VM_FLAVOR_EPHEMERAL} \
        $MANILA_SERVICE_VM_FLAVOR_NAME \
        $MANILA_SERVICE_VM_FLAVOR_REF \
        $MANILA_SERVICE_VM_FLAVOR_RAM \
        $MANILA_SERVICE_VM_FLAVOR_DISK \
        $MANILA_SERVICE_VM_FLAVOR_VCPUS \
        --is-public 'True'

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: Bootstrapper Complete"
################################################################################
