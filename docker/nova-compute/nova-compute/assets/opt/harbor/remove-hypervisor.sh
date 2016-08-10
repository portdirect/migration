#!/bin/bash

# In HarborOS this should match the hostname of the container
HYPERVISOR_HOSTNAME=$(hostname)

# Get the ID of the hypervisor
HYPERVISOR_ID=$(
mysql -sN -h ${MARIADB_SERVICE_HOST} -u ${NOVA_DB_USER} -p${NOVA_DB_PASSWORD} ${NOVA_DB_NAME} <<EOF
SELECT id FROM compute_nodes WHERE hypervisor_hostname="${HYPERVISOR_HOSTNAME}";
EOF
)


# Remove node stats if present in the nova database
mysql -sN -h ${MARIADB_SERVICE_HOST} -u ${NOVA_DB_USER} -p${NOVA_DB_PASSWORD} ${NOVA_DB_NAME} <<EOF
DELETE FROM compute_node_stats WHERE compute_node_id=${HYPERVISOR_ID};
EOF

# Remove the hypervisor from the compute node list
mysql -sN -h ${MARIADB_SERVICE_HOST} -u ${NOVA_DB_USER} -p${NOVA_DB_PASSWORD} ${NOVA_DB_NAME} <<EOF
DELETE FROM compute_nodes WHERE hypervisor_hostname="${HYPERVISOR_HOSTNAME}";
EOF

# Remove the hypervisor from the services list
mysql -sN -h ${MARIADB_SERVICE_HOST} -u ${NOVA_DB_USER} -p${NOVA_DB_PASSWORD} ${NOVA_DB_NAME} <<EOF
DELETE FROM services WHERE host="${HYPERVISOR_HOSTNAME}";
EOF
