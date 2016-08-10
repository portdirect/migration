


DNS_FOWARDER=8.8.8.8

generate_password () {
PWD_LENGTH=$1
openssl rand -hex $PWD_LENGTH | base64 --wrap 0 | fold -w $PWD_LENGTH | sed -n 2p
}

OS_DOMAIN="$(hostname -d)"
IPA_PASSWORD="$(generate_password 128)"
DS_PASSWORD="$(generate_password 128)"
ADMIN_PASSWORD=$IPA_PASSWORD


(
cat /etc/openstack/${OS_DOMAIN}.crt /etc/openstack/${OS_DOMAIN}.key > /etc/openstack/${OS_DOMAIN}.pem
openssl rsa -in /etc/openstack/${OS_DOMAIN}.key -check
openssl x509 -in /etc/openstack/${OS_DOMAIN}.crt -text -noout
) || true
touch /etc/openstack/$(hostname -d).pem
LOADBALANCERS_FRONTEND_SSL_KEY="$(cat /etc/openstack/$(hostname -d).pem | base64 --wrap 0)"


mkdir -p /etc/openstack
cat > /etc/openstack/ok.env << EOF


# IPA DS PASSWORD
IPA_DS_PASSWORD="${DS_PASSWORD}"


# IPA Admin User
IPA_ADMIN_USER='admin'
IPA_ADMIN_PASSWORD="${IPA_PASSWORD}"

# IPA Host Enrollment (sama as admin user for default install)
IPA_HOST_ADMIN_USER='admin'
IPA_HOST_ADMIN_PASSWORD="${IPA_PASSWORD}"

# IPA CA And User Management (sama as admin user for default install)
IPA_USER_ADMIN_USER='admin'
IPA_USER_ADMIN_PASSWORD="${IPA_PASSWORD}"



# Portal
PORTAL_SMTP_HOST=''
PORTAL_SMTP_PORT=''
PORTAL_SMTP_USER=''
PORTAL_SMTP_PASS=''
PORTAL_DEFAULT_FROM_EMAIL=''
PORTAL_DEFAULT_ADMIN_EMAIL=''

# Pxe
HOST_SSH_USER='harbor'
HOST_SSH_KEY_LOC="/home/\${HOST_SSH_USER}/.ssh/id_rsa"
#HOST_ETCD_DISCOVERY_TOKEN='set to manually define discovery url'


# GLUSTERFS
GLUSTERFS_DEVICE="br2"


# MariaDB
DB_ROOT_PASSWORD="$(generate_password 32)"

# MariaDB
MARIADB_DATABASE='mariadb'
MARIADB_PASSWORD="$(generate_password 32)"
MARIADB_USER='mariadb'

# MongoDB
MONGO_DB_USER='ceilometer'
MONGO_DB_NAME='ceilometer'
MONGO_DB_PASSWORD="$(generate_password 32)"


# Core RabbitMQ Creds
RABBITMQ_USER='rabbitmq'
RABBITMQ_PASS="$(generate_password 32)"


# Keystone
KEYSTONE_DB_NAME='keystone'
KEYSTONE_DB_USER='keystone'
KEYSTONE_DB_PASSWORD="$(generate_password 32)"
KEYSTONE_LDAP_USER='keystone'
KEYSTONE_LDAP_PASSWORD="$(generate_password 128)"
KEYSTONE_ADMIN_TOKEN="$(generate_password 512)"
KEYSTONE_ADMIN_USER='admin'
KEYSTONE_ADMIN_PROJECT='admin'
KEYSTONE_ADMIN_PASSWORD="$(generate_password 128)"


# Swift
SWIFT_KEYSTONE_USER='swift'
SWIFT_KEYSTONE_PASSWORD="$(generate_password 128)"
SWIFT_DEVICE='br2'
SWIFT_HASH_PATH_SUFFIX="$(generate_password 8)"
SWIFT_HASH_PATH_PREFIX="$(generate_password 8)"


# Glance
GLANCE_KEYSTONE_USER='glance'
GLANCE_KEYSTONE_PASSWORD="$(generate_password 128)"
GLANCE_DB_NAME='glance'
GLANCE_DB_USER='glance'
GLANCE_DB_PASSWORD="$(generate_password 32)"


# Neutron
NEUTRON_KEYSTONE_USER='neutron'
NEUTRON_KEYSTONE_PASSWORD="$(generate_password 128)"
NEUTRON_DB_NAME='neutron'
NEUTRON_DB_USER='neutron'
NEUTRON_DB_PASSWORD="$(generate_password 32)"
NEUTRON_SHARED_SECRET="$(generate_password 48)"


# Nova
NOVA_KEYSTONE_USER='nova'
NOVA_KEYSTONE_PASSWORD="$(generate_password 128)"
NOVA_DB_NAME='nova'
NOVA_DB_USER='nova'
NOVA_DB_PASSWORD="$(generate_password 32)"
NOVA_API_DB_NAME='nova_api'
NOVA_API_DB_USER='nova'
NOVA_API_DB_PASSWORD="$(generate_password 32)"


# Cinder
CINDER_KEYSTONE_USER='cinder'
CINDER_KEYSTONE_PASSWORD="$(generate_password 128)"
CINDER_DB_NAME='cinder'
CINDER_DB_USER='cinder'
CINDER_DB_PASSWORD="$(generate_password 32)"


# Heat
HEAT_KEYSTONE_USER='heat'
HEAT_KEYSTONE_PASSWORD="$(generate_password 128)"
HEAT_DB_NAME='heat'
HEAT_DB_USER='heat'
HEAT_DB_PASSWORD="$(generate_password 32)"


# Horizon
HORIZON_DB_ROOT_PASSWORD="$(generate_password 32)"
HORIZON_MARIADB_DATABASE='mariadb'
HORIZON_MARIADB_PASSWORD="$(generate_password 32)"
HORIZON_MARIADB_USER='mariadb'
HORIZON_DB_NAME='horizon'
HORIZON_DB_USER='horizon'
HORIZON_DB_PASSWORD="$(generate_password 32)"


# Loadbalancer
LOADBALANCERS_FRONTEND_SSL_KEY="${LOADBALANCERS_FRONTEND_SSL_KEY}"


# Murano
MURANO_DB_USER='murano'
MURANO_DB_NAME='murano'
MURANO_DB_PASSWORD="$(generate_password 32)"
MURANO_KEYSTONE_USER='murano'
MURANO_KEYSTONE_PASSWORD="$(generate_password 128)"
MURANO_RABBITMQ_USER='rabbitmq'
MURANO_RABBITMQ_PASS="$(generate_password 32)"


# Ceilometer
CEILOMETER_KEYSTONE_USER='ceilometer'
CEILOMETER_KEYSTONE_PASSWORD="$(generate_password 128)"
CEILOMETER_METERING_SECRET="$(generate_password 48)"
CEILOMETER_DB_NAME='ceilometer'
CEILOMETER_DB_USER='ceilometer'
CEILOMETER_DB_PASSWORD="$(generate_password 32)"

# Gnocchi
GNOCCHI_KEYSTONE_USER='gnocchi'
GNOCCHI_KEYSTONE_PASSWORD="$(generate_password 128)"
GNOCCHI_DB_NAME='gnocchi'
GNOCCHI_DB_USER='gnocchi'
GNOCCHI_DB_PASSWORD="$(generate_password 32)"
GRAFANA_DB_NAME='grafana'
GRAFANA_DB_USER='grafana'
GRAFANA_DB_PASSWORD="$(generate_password 32)"
GRAFANA_LDAP_USER='grafana'
GRAFANA_LDAP_PASSWORD="$(generate_password 128)"
GRAFANA_SECRET_KEY="$(generate_password 20)"
GRAFANA_SMTP_HOST=''
GRAFANA_SMTP_PORT=''
GRAFANA_SMTP_USER=''
GRAFANA_SMTP_PASS=''
GRAFANA_DEFAULT_FROM_EMAIL=''

# Cloudkitty
CLOUDKITTY_KEYSTONE_USER='cloudkitty'
CLOUDKITTY_KEYSTONE_PASSWORD="$(generate_password 128)"
CLOUDKITTY_FREEIPA_USER='cloudkitty'
CLOUDKITTY_FREEIPA_PASSWORD="$(generate_password 128)"
CLOUDKITTY_DB_NAME='cloudkitty'
CLOUDKITTY_DB_USER='cloudkitty'
CLOUDKITTY_DB_PASSWORD="$(generate_password 32)"

# Barbican
BARBICAN_KEYSTONE_USER='barbican'
BARBICAN_KEYSTONE_PASSWORD="$(generate_password 128)"
BARBICAN_DB_NAME='barbican'
BARBICAN_DB_USER='barbican'
BARBICAN_DB_PASSWORD="$(generate_password 32)"

# Magnum
MAGNUM_KEYSTONE_USER='magnum'
MAGNUM_KEYSTONE_PASSWORD="$(generate_password 128)"
MAGNUM_KEYSTONE_TRUST_PASSWORD="$(generate_password 128)"
MAGNUM_DB_NAME='magnum'
MAGNUM_DB_USER='magnum'
MAGNUM_DB_PASSWORD="$(generate_password 32)"

# Trove
TROVE_KEYSTONE_USER='trove'
TROVE_KEYSTONE_PASSWORD="$(generate_password 128)"
TROVE_KEYSTONE_TRUST_PASSWORD="$(generate_password 128)"
TROVE_DB_NAME='trove'
TROVE_DB_USER='trove'
TROVE_DB_PASSWORD="$(generate_password 32)"
TROVE_RABBITMQ_USER='rabbitmq'
TROVE_RABBITMQ_PASS="$(generate_password 32)"


# Manila
MANILA_KEYSTONE_USER='manila'
MANILA_KEYSTONE_PASSWORD="$(generate_password 128)"
MANILA_KEYSTONE_TRUST_PASSWORD="$(generate_password 128)"
MANILA_DB_NAME='manila'
MANILA_DB_USER='manila'
MANILA_DB_PASSWORD="$(generate_password 32)"

# Designate
DESIGNATE_KEYSTONE_USER='designate'
DESIGNATE_KEYSTONE_PASSWORD="$(generate_password 128)"
DESIGNATE_DB_NAME='designate'
DESIGNATE_DB_USER='designate'
DESIGNATE_DB_PASSWORD="$(generate_password 32)"
DESIGNATE_POOL_DB_NAME='designate_pool'
DESIGNATE_POOL_DB_USER='designate_pool'
DESIGNATE_POOL_DB_PASSWORD="$(generate_password 32)"
DESIGNATE_PDNS_DB_NAME='designate_pdns'
DESIGNATE_PDNS_DB_USER='designate_pdns'
DESIGNATE_PDNS_DB_PASSWORD="$(generate_password 32)"

# Foreman
FOREMAN_DB_NAME='foreman'
FOREMAN_DB_USER='foreman'
FOREMAN_DB_PASSWORD="$(generate_password 32)"
FOREMAN_OAUTH_KEY="$(generate_password 32)"
FOREMAN_OAUTH_SECRET="$(generate_password 32)"
FOREMAN_SMTP_HOST=''
FOREMAN_SMTP_PORT=''
FOREMAN_SMTP_USER=''
FOREMAN_SMTP_PASS=''
FOREMAN_DEFAULT_FROM_EMAIL=''
FOREMAN_DEFAULT_ADMIN_EMAIL=''


# Ipsilon
IPSILON_DB_ROOT_NAME='root'
IPSILON_DB_ROOT_USER='root'
IPSILON_DB_ROOT_PASSWORD="$(generate_password 32)"
IPSILON_DB_NAME='ipsilon'
IPSILON_DB_USER='ipsilon'
IPSILON_DB_PASSWORD="$(generate_password 32)"
IPSILON_ADMIN_DB_NAME='ipsilon_admin'
IPSILON_ADMIN_DB_USER='ipsilon_admin'
IPSILON_ADMIN_DB_PASSWORD="$(generate_password 32)"
IPSILON_USERS_DB_NAME='ipsilon_users'
IPSILON_USERS_DB_USER='ipsilon_users'
IPSILON_USERS_DB_PASSWORD="$(generate_password 32)"
IPSILON_TRANS_DB_NAME='ipsilon_trans'
IPSILON_TRANS_DB_USER='ipsilon_trans'
IPSILON_TRANS_DB_PASSWORD="$(generate_password 32)"
IPSILON_SAMLSESSION_DB_NAME='ipsilon_session'
IPSILON_SAMLSESSION_DB_USER='ipsilon_session'
IPSILON_SAMLSESSION_DB_PASSWORD="$(generate_password 32)"
IPSILON_SAML2SESSION_DB_NAME='ipsilon_saml'
IPSILON_SAML2SESSION_DB_USER='ipsilon_saml'
IPSILON_SAML2SESSION_DB_PASSWORD="$(generate_password 32)"

EOF


ls /etc/openstack/openstack.env || cp /etc/openstack/ok.env /etc/openstack/openstack.env

source /etc/openstack/openstack.env
IPA_DATA_DIR=/var/lib/harbor/freeipa-master
mkdir -p ${IPA_DATA_DIR}
ls $IPA_DATA_DIR/ipa-server-install-options || (
cat > $IPA_DATA_DIR/ipa-server-install-options << EOF
--ds-password=${IPA_DS_PASSWORD}
--admin-password=${IPA_ADMIN_PASSWORD}
EOF
)
