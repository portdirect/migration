sudo yum install -y \
    epel-release \
    centos-release-gluster37 \
    centos-release-openstack-mitaka \
    git

sudo yum install -y openstack-packstack


sudo systemctl disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable NetworkManager
sudo systemctl stop NetworkManager
sudo systemctl enable network
sudo systemctl start network

ANSWER_FILE=~/packstack-answers.txt
packstack --gen-answer-file=${ANSWER_FILE} \
--keystone-admin-passwd=password \
--keystone-demo-passwd=password \
--default-password=password \
--allinone \
--provision-demo=y \
--os-swift-install=n \
--os-heat-install=n \
--os-aodh-install=n \
--os-gnocchi-install=n \
--os-ceilometer-install=n \
--os-neutron-install=y \
--os-neutron-lbaas-install=n \
--os-neutron-metering-agent-install=n \
--provision-demo-floatrange=100.64.0.1/24

packstack --answer-file=${ANSWER_FILE}



source ~/keystonerc_admin
nova keypair-add --pub-key ~/.ssh/id_rsa.pub demo-key
neutron net-create demo
neutron subnet-create demo --name demo-sub \
  --gateway 10.142.0.254 --dns 8.8.8.8  10.142.0.0/24
neutron security-group-create demo --description "security rules to access demo instances"
nova secgroup-add-rule demo tcp 22 22 0.0.0.0/0
nova secgroup-add-rule demo tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule demo udp 1 65535 0.0.0.0/0
nova secgroup-add-rule demo icmp -1 -1 0.0.0.0/0

neutron router-create demo
neutron router-gateway-set demo public
neutron router-interface-add demo demo-sub

nova image-list

nova boot --flavor m1.xlarge --image "ubuntu-14.04"  \
       --nic net-name=demo,v4-fixed-ip=10.142.0.2 \
       --security-group demo --key-name demo-key ost-controller

neutron floatingip-create public

nova floating-ip-associate ost-controller  192.168.122.4
rm -rf rm /root/.ssh/known_hosts
ssh ubuntu@192.168.122.4

(



sudo apt-get update

curl -L https://bootstrap.pypa.io/get-pip.py | sudo -H python -
sudo apt-get install -y git
sudo pip install --upgrade pip
sudo apt-get -y install python-dev
sudo pip install networking-l2gw



git clone --depth 1 https://github.com/openstack-dev/devstack

cd ~/devstack

sudo cat >> local.conf << 'EOF'
[[local|localrc]]
OFFLINE=No
RECLONE=No

ENABLED_SERVICES=""

Q_PLUGIN=midonet
enable_plugin networking-midonet http://github.com/portdirect/networking-midonet.git
MIDONET_PLUGIN=midonet_v2
MIDONET_CLIENT=midonet.neutron.client.api.MidonetApiClient
MIDONET_USE_ZOOM=True
Q_SERVICE_PLUGIN_CLASSES=midonet_l3
NEUTRON_LBAAS_SERVICE_PROVIDERV1="LOADBALANCER:Midonet:midonet.neutron.services.loadbalancer.driver.MidonetLoadbalancerDriver:default"


enable_plugin networking-l2gw https://github.com/openstack/networking-l2gw
enable_service l2gw-plugin
Q_PLUGIN_EXTRA_CONF_PATH=/etc/neutron
Q_PLUGIN_EXTRA_CONF_FILES=(l2gw_plugin.ini)
L2GW_PLUGIN="midonet_l2gw"
NETWORKING_L2GW_SERVICE_DRIVER="L2GW:Midonet:midonet.neutron.services.l2gateway.service_drivers.l2gw_midonet.MidonetL2gwDriver:default"


PUBLIC_INTERFACE=eth0
MIDONET_USE_UPLINK_NAT=True
UPLINK_CIDR=172.19.0.0/24

# Credentials
ADMIN_PASSWORD=pass
DATABASE_PASSWORD=pass
RABBIT_PASSWORD=pass
SERVICE_PASSWORD=pass
SERVICE_TOKEN=pass


MIDONET_USE_METADATA=True
Q_METADATA_ENABLED=True
disable_service q-dhcp
disable_service q-meta
disable_service n-cpu


enable_service q-svc
enable_service q-lbaas
enable_service q-fwaas
enable_service neutron
enable_service key
enable_service mysql
enable_service rabbit
enable_service horizon
enable_service n-api,n-crt,n-obj,n-cond,n-sch
enable_service g-api,g-reg




[[post-config|$NEUTRON_CONF_DIR/neutron_lbaas.conf]]
[service_providers]
service_provider = LOADBALANCER:Haproxy:neutron_lbaas.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
service_provider = LOADBALANCER:Midonet:midonet.neutron.services.loadbalancer.driver.MidonetLoadbalancerDriver

# Log all output to files
LOGFILE=$HOME/devstack.log
SCREEN_LOGDIR=$HOME/logs
EOF

./stack.sh
)

cat > config.cfg <<EOF
[sandbox]
docker_socket = tcp://127.0.0.1:2375
EOF

sandbox-manage -c config.cfg images-list

# hack for getting to internet from the containers
sudo iptables -t nat -A POSTROUTING -s 172.24.4.1/24 -d 0.0.0.0/0 -j MASQUERADE



yum install -y wget
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
bunzip2 coreos_production_openstack_image.img.bz2
glance image-create --name CoreOS \
  --container-format bare \
  --disk-format qcow2 \
  --file coreos_production_openstack_image.img

curl -L https://raw.githubusercontent.com/portdirect/kuryr/k8s/contrib/demo/os/cloud-config-master.yaml > cloud-config-master.yaml
nova boot --flavor m1.medium --image "CoreOS"  \
       --nic net-name=demo,v4-fixed-ip=10.142.0.3 \
       --security-group demo --key-name demo-key k8s-controller \
       --user-data cloud-config-master.yaml



       nova floating-ip-associate k8s-controller  192.168.122.5


curl -L https://raw.githubusercontent.com/portdirect/kuryr/k8s/contrib/demo/os/cloud-config-worker1.yaml > cloud-config-worker1.yaml
nova boot --flavor m1.medium --image "CoreOS"  \
     --nic net-name=demo,v4-fixed-ip=10.142.0.4 \
     --security-group demo --key-name demo-key k8s-worker1 \
     --user-data cloud-config-worker1.yaml

            nova floating-ip-associate k8s-worker1  192.168.122.6
curl -L https://raw.githubusercontent.com/portdirect/kuryr/k8s/contrib/demo/os/cloud-config-worker2.yaml > cloud-config-worker2.yaml
nova boot --flavor m1.medium --image "CoreOS"  \
     --nic net-name=demo,v4-fixed-ip=10.142.0.5 \
     --security-group demo --key-name demo-key k8s-worker2 \
     --user-data cloud-config-worker2.yaml
            nova floating-ip-associate k8s-worker2  192.168.122.7


source ~/devstack/openrc admin admin
neutron agent-list -c agent_type -c host -c alive -c admin_state_up


MIDONET_TUNNEL_ZONE=$(midonet-cli -e tunnel-zone create  name test-tz type vxlan)
echo ${MIDONET_TUNNEL_ZONE}


midonet-cli -e host list
midonet-cli -e tunnel-zone  ${MIDONET_TUNNEL_ZONE} add \
  member host $(midonet-cli -e host list | grep $(hostname) | awk '{ print $2 }') address 10.142.0.2
midonet-cli -e tunnel-zone ${MIDONET_TUNNEL_ZONE} add \
  member host 2a3b9405-818a-496b-bf75-9a53c9c45b0e address 10.142.0.4
midonet-cli -e tunnel-zone ${MIDONET_TUNNEL_ZONE} add \
  member host 80870762-6bee-4146-bfd8-fb5ae3f5477a address 10.142.0.5


neutron router-gateway-set raven-default-router public

kubectl run --image=nginx --replicas=2 nginx
kubectl run --image=port/base --replicas=2 base -- ping 8.8.8.8
kubectl expose deployment nginx --port=80

sudo iptables -t nat -A POSTROUTING -s 172.24.4.1/24 -d 0.0.0.0/0 -j MASQUERADE




kubectl create namespace k8s-link
kubectl run --image=port/base --replicas=2 --namespace k8s-link base -- ping 10.0.0.45
curl -L https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework > /opt/bin/pipework
chmod +x /opt/bin/pipework













neutron port-create mn-uplink-net --binding:host_id k8s-worker1.novalocal --binding:profile type=dict interface_name=<INTERFACE_NAME> --fixed-ip ip_address=<IP_ADDR>

source openrc admin admin





HOST_ID=k8s-worker2.novalocal
PUBLIC_SUBNET_NAME="public-subnet"
EDGE_ROUTER_NAME="mn-edge"

# Neutron net/subnet/port for uplink
UPLINK_NET_NAME="mn-uplink-net-${HOST_ID}"
UPLINK_SUBNET_NAME="mn-uplink-subnet-${HOST_ID}"
UPLINK_PORT_NAME="mn-uplink-port-${HOST_ID}"
# Veth pair
UPLINK_VIRT_IFNAME="mn-uplink-virt"
UPLINK_HOST_IFNAME="mn-uplink-host"
# NOTE(yamamoto): These addresses are taken from create_fake_uplink.sh
UPLINK_CIDR="172.19.1.0/30"
UPLINK_PREFIX_LEN="30"
UPLINK_VIRT_IP="172.19.1.1"
UPLINK_HOST_IP="172.19.1.2"

sudo ip link add name ${UPLINK_HOST_IFNAME} type veth \
    peer name ${UPLINK_VIRT_IFNAME}
for name in ${UPLINK_HOST_IFNAME} ${UPLINK_VIRT_IFNAME}; do
    sudo ip addr flush ${name}
    sudo ip link set dev ${name} up
done

# Configure edge router and uplink network
neutron --os-project-name admin \
    router-create \
    ${EDGE_ROUTER_NAME}
neutron --os-project-name admin \
    router-interface-add \
    ${EDGE_ROUTER_NAME} ${PUBLIC_SUBNET_NAME}
neutron --os-project-name admin \
    net-create \
    ${UPLINK_NET_NAME} \
    --provider:network_type uplink
neutron --os-project-name admin \
    subnet-create \
    --disable-dhcp --name ${UPLINK_SUBNET_NAME} \
    ${UPLINK_NET_NAME} ${UPLINK_CIDR}
neutron --os-project-name admin \
    port-create ${UPLINK_NET_NAME} \
    --name ${UPLINK_PORT_NAME} \
    --binding:host_id ${HOST_ID} \
    --binding:profile type=dict interface_name=${UPLINK_VIRT_IFNAME} \
    --fixed-ip ip_address=${UPLINK_VIRT_IP}
neutron --os-project-name admin \
    router-interface-add \
    ${EDGE_ROUTER_NAME} port=${UPLINK_PORT_NAME}
neutron --os-project-name admin \
    router-update \
    ${EDGE_ROUTER_NAME} \
    --routes type=dict list=true \
        destination=0.0.0.0/0,nexthop=${UPLINK_HOST_IP}

# Configure host side
sudo ip addr add ${UPLINK_HOST_IP}/${UPLINK_PREFIX_LEN} \
    dev ${UPLINK_HOST_IFNAME}
























HOST_ID=$(hostname -s)
SERVICE_SUBNET_NAME="raven-default-service-${HOST_ID}"
EDGE_ROUTER_NAME="raven-default-router"

# Neutron net/subnet/port for uplink
UPLINK_NET_NAME="k8s-uplink-${HOST_ID}"
UPLINK_SUBNET_NAME="k8s-uplink-${HOST_ID}"
UPLINK_PORT_NAME="k8s-uplink-${HOST_ID}"
# Veth pair
UPLINK_VIRT_IFNAME="k8s-uplink-virt"
UPLINK_HOST_IFNAME="k8s-uplink-host"
# NOTE(yamamoto): These addresses are taken from create_fake_uplink.sh
UPLINK_CIDR="172.20.1.0/30"
UPLINK_PREFIX_LEN="30"
UPLINK_VIRT_IP="172.20.1.1"
UPLINK_HOST_IP="172.20.1.2"

sudo ip link add name ${UPLINK_HOST_IFNAME} type veth \
  peer name ${UPLINK_VIRT_IFNAME}
for name in ${UPLINK_HOST_IFNAME} ${UPLINK_VIRT_IFNAME}; do
  sudo ip addr flush ${name}
  sudo ip link set dev ${name} up
done


    neutron --os-project-name admin \
        net-create \
        ${UPLINK_NET_NAME} \
        --provider:network_type uplink
    neutron --os-project-name admin \
        subnet-create \
        --disable-dhcp --name ${UPLINK_SUBNET_NAME} \
        ${UPLINK_NET_NAME} ${UPLINK_CIDR}
    neutron --os-project-name admin \
        port-create ${UPLINK_NET_NAME} \
        --name ${UPLINK_PORT_NAME} \
        --binding:host_id ${HOST_ID} \
        --binding:profile type=dict interface_name=${UPLINK_VIRT_IFNAME} \
        --fixed-ip ip_address=${UPLINK_VIRT_IP}
    neutron --os-project-name admin \
        router-interface-add \
        ${EDGE_ROUTER_NAME} port=${UPLINK_PORT_NAME}
    neutron --os-project-name admin \
        router-update \
        ${EDGE_ROUTER_NAME} \
        --routes type=dict list=true \
            destination=0.0.0.0/0,nexthop=${UPLINK_HOST_IP}

    # Configure host side
    sudo ip addr add ${UPLINK_HOST_IP}/${UPLINK_PREFIX_LEN} \
        dev ${UPLINK_HOST_IFNAME}





     via 172.19.0.1 dev mn-uplink-host
10.142.0.0/24 dev eth0  proto kernel  scope link  src 10.142.0.2
169.254.123.0/24 dev midorecirc-host  proto kernel  scope link  src 169.254.123.1
169.254.169.254 via 10.142.0.254 dev eth0
172.19.0.0/30 dev mn-uplink-host  proto kernel  scope link  src 172.19.0.2
172.24.4.0/24 via 172.19.0.1 dev mn-uplink-host





sudo ip route replace 172.24.4.0/24 via 172.19.1.1
sudo ip route replace 10.0.0.0/24 via 172.20.1.2
