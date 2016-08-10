#!/bin/bash


docker-system.sh run -it --net=host --name ovs-bootstrap docker.io/harboros/utils-network:latest bash
docker-system.sh exec -it ovs-bootstrap apk update
docker-system.sh exec -it ovs-bootstrap apk add sipcalc
etcdctl rm -recursive /ovs



OVS_NETWORK="10.96.0.0/12"
OVS_DEV=br0
OVS_DOCKER_CIDR=24


OVS_CIDR=${OVS_NETWORK#*/}
OVS_NETWORK_START=${OVS_NETWORK%/*}
OVS_IP=$(ip -f inet -o addr show $OVS_DEV|cut -d\  -f 7 | cut -d/ -f 1)
HOSTNAME=$(hostname)

if (etcdctl ls -recursive /ovs/nodes | grep -q $HOSTNAME ); then
    echo "Node already registered"
    EXISTING_IP=$(etcdctl get /ovs/nodes/$HOSTNAME)
    echo EXISTING_IP=$EXISTING_IP
    if [ "${EXISTING_IP}" != "${OVS_IP}" ]; then
      echo "Node has already been registered, but ther is an IP mismatch, I'm not clever enought to deal with this yet. Exiting"
      #exit 1
    fi
    etcdctl ls -recursive /ovs/network/subnets | \
      while read ETCD_KEY; do
        SUBNET_KEY=$(etcdctl get ${ETCD_KEY})
        if [ "${SUBNET_KEY}" == "${OVS_IP}" ]; then
          OVS_DOCKER_SUBNET=$(echo ${ETCD_KEY#/ovs/network/subnets/} | tr '-' '/')
          echo "This node has the subnet $OVS_DOCKER_SUBNET"
        else
          echo "This nodes IP not found in the list of registered subnets, exiting"
          #exit 1
        fi
      done
else
    echo "Node not registered, doing that now"
    etcdctl set /ovs/nodes/$HOSTNAME ${OVS_IP}

    if etcdctl ls /ovs/network/subnets; then
      DOCKER_BRIDGE_SUBNET=${OVS_NETWORK_START}
      etcdctl ls --sort /ovs/network/subnets | \
        while read ETCD_KEY; do
          OVS_DOCKER_SUBNET=$(echo ${ETCD_KEY#/ovs/network/subnets/} | tr '-' '/')
          echo "Processing $OVS_DOCKER_SUBNET"
          NEXT_DOCKER_BRIDGE_SUBNET=$(docker-system.sh exec ovs-bootstrap sipcalc -n 2 $OVS_DOCKER_SUBNET | tac | grep -m 1 Network | awk '{print $3}')
          if [ "${OVS_DOCKER_SUBNET}" == "${DOCKER_BRIDGE_SUBNET}/${OVS_DOCKER_CIDR}" ]; then
            echo "Tried subnet: $DOCKER_BRIDGE_SUBNET/${OVS_DOCKER_CIDR} but a host already has it"
          else
            if etcdctl get /ovs/network/subnets/${DOCKER_BRIDGE_SUBNET}/${OVS_DOCKER_CIDR}; then
              echo "Subnet: ${DOCKER_BRIDGE_SUBNET}/${OVS_DOCKER_CIDR} has been allocated to another node"
            else
              echo "Subnet: ${DOCKER_BRIDGE_SUBNET}/${OVS_DOCKER_CIDR} has been allocated to this node"
              etcdctl set /ovs/network/subnets/${DOCKER_BRIDGE_SUBNET}-${OVS_DOCKER_CIDR} ${OVS_IP}
              break
            fi
          fi
          DOCKER_BRIDGE_SUBNET=${NEXT_DOCKER_BRIDGE_SUBNET}
        done
    else
        echo "No Other nodes found, this node will be granted the 1st avalible subnet ${OVS_NETWORK_START}/${OVS_DOCKER_CIDR}"
        etcdctl set /ovs/network/subnets/${DOCKER_BRIDGE_SUBNET}-${OVS_DOCKER_CIDR} ${OVS_IP}
        etcdctl set /ovs/network/nodes/$HOSTNAME ${DOCKER_BRIDGE_SUBNET}/${OVS_DOCKER_CIDR}
    fi

fi









OVS_NETWORK="10.96.0.0/12"
OVS_DEV=br0
OVS_DOCKER_CIDR=24



OVS_CIDR=${OVS_NETWORK#*/}
OVS_NETWORK_START=${OVS_NETWORK%/*}
OVS_IP=$(ip -f inet -o addr show $OVS_DEV|cut -d\  -f 7 | cut -d/ -f 1)
HOSTNAME=$(hostname)


OVS_HOST_SUBNET=$(etcdctl get /ovs/network/nodes/$HOSTNAME)
DOCKER_BRIDGE_IP=$(sipcalc ${OVS_HOST_SUBNET} | grep "Usable range" | awk '{print $4}')
DOCKER_BRIDGE_ADDRESS="${DOCKER_BRIDGE_IP}/${OVS_CIDR}"

DOCKER_BRIDGE_NAME=docker0
OVS_BRIDGE_NAME=${DOCKER_BRIDGE_NAME}_ovs


echo "Writing OVS Start script" 

# Deactivate the docker0 bridge
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock exec -it ovs ip link set ${DOCKER_BRIDGE_NAME} down
# Remove the docker0 bridge
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock exec -it ovs brctl delbr ${DOCKER_BRIDGE_NAME}
# Delete the Open vSwitch bridge
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock exec -it ovs ovs-vsctl del-br ${OVS_BRIDGE_NAME}
# Add the docker0 bridge
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock exec -it ovs brctl addbr ${DOCKER_BRIDGE_NAME}
# Set up the IP for the docker0 bridge
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock exec -it ovs ip a add ${DOCKER_BRIDGE_ADDRESS} dev ${DOCKER_BRIDGE_NAME}
# Activate the bridge
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock exec -it ovs ip link set ${DOCKER_BRIDGE_NAME} up
# Add the br0 Open vSwitch bridge
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock exec -it ovs ovs-vsctl add-br ${OVS_BRIDGE_NAME}
# Add the br0 bridge to docker0 bridge
/usr/bin/docker -H unix:///var/run/docker-bootstrap.sock exec -it ovs brctl addif ${DOCKER_BRIDGE_NAME} ${OVS_BRIDGE_NAME}
)



register_node () {
  etcdctl ls -recursive /ovs/nodes | grep $HOSTNAME | \
    while read ETCD_KEY; do
      ROLE=$(etcdctl get ${ETCD_KEY})

      fi
    done

}
populate_gluster_volumes

ovs-vsctl show












#
#
# # Create the tunnel to the other host and attach it to the
# # br0 bridge
# ovs-vsctl add-port $OVS_BRIDGE_NAME gre0 -- set interface gre0 type=gre options:remote_ip=$REMOTE_IP
#
#
# ovs-vsctl show
#
#
# # iptables rules
#
# # Enable NAT
# LOCAL_SUBNET=10.96.8.0/24
# LOCAL_SUBNET=10.96.83.0/24
# iptables -t nat -A POSTROUTING -s ${LOCAL_SUBNET} ! -d${LOCAL_SUBNET} -j MASQUERADE
# # Accept incoming packets for existing connections
# iptables -A FORWARD -o ${BRIDGE_NAME} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# # Accept all non-intercontainer outgoing packets
# iptables -A FORWARD -i ${BRIDGE_NAME} ! -o ${BRIDGE_NAME} -j ACCEPT
# # By default allow all outgoing traffic
# iptables -A FORWARD -i ${BRIDGE_NAME} -o ${BRIDGE_NAME} -j ACCEPT
#
# # Restart Docker daemon to use the new BRIDGE_NAME
# service docker restart
#
#
#
# . /etc/sysconfig/docker
# . /etc/sysconfig/docker-storage
# /usr/bin/docker daemon \
#                 --bridge=docker0 \
#                 $OPTIONS \
#                 $DOCKER_STORAGE_OPTIONS \
#                 $BLOCK_REGISTRY \
#                 $INSECURE_REGISTRY
