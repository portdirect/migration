#!/bin/sh

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Admin Keystone"
################################################################################
wait-http $KEYSTONE_SERVICE_HOST:35357

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For Public Keystone"
################################################################################
wait-http $KEYSTONE_SERVICE_HOST:5000

openstack user show "admin"
openstack project show "admin"
openstack project show "service" || openstack project create "service"


openstack user create --project "service" --password "password" --enable "neutron"
openstack role add --project "service" --user "neutron" "admin"
openstack role add --domain "default" --user "neutron" "admin"
openstack service create --name "neutron" --description "OpenStack Networking" "network"
openstack endpoint create --region "RegionOne" "network" public "http://${CONTROLLER_IP}:9696"
openstack endpoint create --region "RegionOne" "network" admin "http://${CONTROLLER_IP}:9696"
openstack endpoint create --region "RegionOne" "network" internal "http://${CONTROLLER_IP}:9696"


openstack user create --project "service" --password "password" --enable "nova"
openstack role add --project "service" --user "nova" "admin"
openstack role add --domain "default" --user "nova" "admin"
openstack service create --name "nova" --description "OpenStack Compute" "compute"
openstack endpoint create --region "RegionOne" "compute" public "http://${CONTROLLER_IP}:8774/v2.1/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "compute" internal "http://${CONTROLLER_IP}:8774/v2.1/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "compute" admin "http://${CONTROLLER_IP}:8774/v2.1/%(tenant_id)s"


openstack user create --project "service" --password "password" --enable "glance"
openstack role add --project "service" --user "glance" "admin"
openstack role add --domain "default" --user "glance" "admin"
openstack service create --name "glance" --description "OpenStack Images" "image"
openstack endpoint create --region "RegionOne" "image" public "http://${CONTROLLER_IP}:9292"
openstack endpoint create --region "RegionOne" "image" internal "http://${CONTROLLER_IP}:9292"
openstack endpoint create --region "RegionOne" "image" admin "http://${CONTROLLER_IP}:9292"



openstack user create --project "service" --password "password" --enable "cinder"
openstack role add --project "service" --user "cinder" "admin"
openstack role add --domain "default" --user "cinder" "admin"
openstack service create --name "cinder" --description "OpenStack Block Storage" "volume"
openstack service create --name "cinderv2" --description "OpenStack Block Storage" "volumev2"
openstack service create --name "cinderv3" --description "OpenStack Block Storage" "volumev3"
openstack endpoint create --region "RegionOne" "volume" public "http://${CONTROLLER_IP}:8776/v1/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "volume" internal "http://${CONTROLLER_IP}:8776/v1/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "volume" admin "http://${CONTROLLER_IP}:8776/v1/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "volumev2" public "http://${CONTROLLER_IP}:8776/v2/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "volumev2" internal "http://${CONTROLLER_IP}:8776/v2/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "volumev2" admin "http://${CONTROLLER_IP}:8776/v2/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "volumev3" public "http://${CONTROLLER_IP}:8776/v3/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "volumev3" internal "http://${CONTROLLER_IP}:8776/v3/%(tenant_id)s"
openstack endpoint create --region "RegionOne" "volumev3" admin "http://${CONTROLLER_IP}:8776/v3/%(tenant_id)s"


sleep 20s
openstack quota set \
--routers 10 \
--subnetpools 100 \
--ports 1000 \
--subnets 100 \
--networks 100 \
--secgroup-rules 1000 \
--secgroups 10 \
--floating-ips 100 \
admin



openstack volume type create --property volume_backend_name="lvmdriver-1" lvmdriver-1
