yum install -y \
    epel-release \
    centos-release-gluster37 \
    centos-release-openstack-mitaka \
    git

yum install -y openstack-packstack


systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network

ANSWER_FILE=/root/packstack-answers.txt
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
--provision-demo-floatrange=192.168.122.1/24

packstack --answer-file=/root/packstack-answers.txt



source /root/keystonerc_demo
nova keypair-add --pub-key ~/.ssh/id_rsa.pub demo-key
neutron net-create demo
neutron subnet-create demo --name demo-sub \
  --gateway 10.142.0.254 --dns 8.8.8.8  10.142.0.0/24
neutron security-group-create demo --description "security rules to access demo instances"
nova secgroup-add-rule demo tcp 22 22 0.0.0.0/0
nova secgroup-add-rule demo tcp 1 65535 10.142.0.0/24
nova secgroup-add-rule demo udp 1 65535 10.142.0.0/24
nova secgroup-add-rule demo icmp -1 -1 10.142.0.0/24

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

Q_ENABLE_DRAGONFLOW_LOCAL_CONTROLLER=True

DATABASE_PASSWORD=password
RABBIT_PASSWORD=password
SERVICE_PASSWORD=password
SERVICE_TOKEN=password
ADMIN_PASSWORD=password

# USE_ML2_PLUGIN=True
# ML2_L3_PLUGIN=df-l3
# Q_ML2_PLUGIN_MECHANISM_DRIVERS=df

enable_plugin dragonflow https://github.com/openstack/dragonflow
enable_service df-etcd
enable_service df-etcd-server
enable_service df-controller
enable_service df-ext-services
enable_service df-zmq-publisher-service


disable_service n-net
disable_service n-cpu
enable_service q-svc
enable_service df-l3-agent
disable_service heat
disable_service tempest

# Enable q-meta once nova is being used.
#enable_service q-meta

# We have to disable the neutron L2 agent. DF does not use the L2 agent.
disable_service q-agt

# We have to disable the neutron dhcp agent. DF does not use the dhcp agent.
disable_service q-dhcp

[[post-config|\$NEUTRON_CONF]]
[DEFAULT]
router_distributed=True
EOF


enable_plugin neutron-lbaas https://github.com/openstack/neutron-lbaas
enable_plugin neutron-lbaas-dashboard https://github.com/openstack/neutron-lbaas-dashboard
NEUTRON_LBAAS_SERVICE_PROVIDERV2="LOADBALANCERV2:Haproxy:neutron_lbaas.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default"
enable_service q-lbaasv2





curl -L https://raw.githubusercontent.com/portdirect/kuryr/k8s/contrib/demo/os/centos-ovs.sh > centos-ovs.sh
nova boot --flavor m1.medium --image "centos-7"  \
       --nic net-name=demo,v4-fixed-ip=10.142.0.3 \
       --security-group demo --key-name demo-key k8s-controller \
       --user-data centos-ovs.sh
nova floating-ip-associate k8s-controller  192.168.122.5


/usr/bin/docker run -d \
--name etcd \
--net host \
--volume=/var/etcd \
quay.io/coreos/etcd:v3.0.1 \
/usr/local/bin/etcd --proxy 'on' \
                    --initial-cluster 'default=http://10.142.0.2:2380' \
                    --listen-client-urls 'http://localhost:2379,http://0.0.0.0:4001'





/usr/bin/docker run -d --name kube-setup-files \
                    --net=host \
                    --volume=/data:/data \
                    gcr.io/google_containers/hyperkube-amd64:v1.3.0 \
                    /setup-files.sh \
                    IP:10.142.0.3,DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc,DNS:kubernetes.default.svc.cluster.local


/usr/bin/docker run -d --name kube-apiserver --net=host \
          --volume=/data:/srv/kubernetes \
          gcr.io/google_containers/hyperkube-amd64:v1.3.0 \
          /hyperkube apiserver \
            --service-cluster-ip-range=10.0.0.1/24 \
            --insecure-bind-address=0.0.0.0 \
            --insecure-port=8080 \
            --etcd-servers=http://127.0.0.1:2379 \
            --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota \
            --client-ca-file=/srv/kubernetes/ca.crt \
            --basic-auth-file=/srv/kubernetes/basic_auth.csv \
            --min-request-timeout=300 \
            --tls-cert-file=/srv/kubernetes/server.cert \
            --tls-private-key-file=/srv/kubernetes/server.key \
            --token-auth-file=/srv/kubernetes/known_tokens.csv \
            --allow-privileged=true \
            --v=2 \
            --logtostderr=true

/usr/bin/docker run -d --name kube-controller-manager --net=host \
          --volume=/data:/srv/kubernetes \
          gcr.io/google_containers/hyperkube-amd64:v1.3.0 \
          /hyperkube controller-manager \
            --master=127.0.0.1:8080 \
            --service-account-private-key-file=/srv/kubernetes/server.key \
            --root-ca-file=/srv/kubernetes/ca.crt \
            --min-resync-period=3m \
            --v=2 \
            --logtostderr=true



/usr/bin/docker run -d --name kube-scheduler --net=host \
          gcr.io/google_containers/hyperkube-amd64:v1.3.0 \
          /hyperkube scheduler \
            --master=127.0.0.1:8080 \
            --v=2 \
            --logtostderr=true


/usr/bin/docker run --name kuryr-raven --net=host \
          -e SERVICE_CLUSTER_IP_RANGE=10.0.0.0/24 \
          -e SERVICE_USER=admin \
          -e SERVICE_TENANT_NAME=admin \
          -e SERVICE_PASSWORD=password \
          -e IDENTITY_URL=http://10.142.0.2:35357/v2.0 \
          -e OS_URL=http://10.142.0.2:9696 \
          -e K8S_API=http://127.0.0.1:8080 \
          -v /var/log/kuryr:/var/log/kuryr \
          docker.io/port/system-raven:latest






docker run -d \
    --net=host \
    --pid=host \
    --name dragonflow-agent \
    --privileged \
    --cap-add NET_ADMIN \
    -v /dev/net:/dev/net:rw \
    -v /var/run/netns:/var/run/netns:rw \
    -v /var/run/openvswitch:/var/run/openvswitch:rw \
    docker.io/port/dragonflow-agent:latest /start.sh



/usr/bin/docker run --name kubelet -d \
          -e MASTER_IP=10.142.0.3 \
          --volume=/:/rootfs:ro \
          -v /dev/net:/dev/net:rw \
          -v /var/run/netns:/var/run/netns:rw \
          -v /var/run/openvswitch:/var/run/openvswitch:rw \
          --volume=/sys:/sys:ro \
          --volume=/var/lib/docker/:/var/lib/docker:rw \
          --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
          --volume=/var/run:/var/run:rw \
          --volume=/var/log/kuryr:/var/log/kuryr \
          --net=host \
          --privileged=true \
          --pid=host \
          docker.io/port/system-kubelet:latest /kubelet




NETWORK_ID=431acd9a-f787-4e07-9278-b7ef047f2553
# HOST_ID=myhost.my-domain.com  #
Create the port in neutron

neutron port-create --name testport \
                  --binding:host_id=$HOST_ID \
                  $NETWORK_ID

neutron port-create --name test-port --binding:host_id=$(hostname) --device-owner cloud --fixed-ip subnet_id=eb2cadf0-3b44-436e-a252-e8dacd5be1d8 coke


ID=d2b141d2-3c02-4417-b8d5-5723e4170f77
MAC=fa:16:3e:90:c5:25
NAME=bdc79368-veth
ovs-vsctl -- --may-exist add-port br-int ${NAME}  \
-- set Interface ${NAME} type=internal \
-- set Interface ${NAME} external-ids:iface-status=active \
-- set Interface ${NAME} external-ids:attached-mac=${MAC} \
-- set Interface ${NAME} external-ids:iface-id=${ID}


nova boot --flavor m1.medium --image "centos-7"  \
     --nic net-name=demo,v4-fixed-ip=10.142.0.4 \
     --security-group demo --key-name demo-key k8s-worker1 \
     --user-data centos-ovs.sh
nova floating-ip-associate k8s-worker1  192.168.122.6

nova boot --flavor m1.medium --image "centos-7"  \
     --nic net-name=demo,v4-fixed-ip=10.142.0.5 \
     --security-group demo --key-name demo-key k8s-worker2
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
