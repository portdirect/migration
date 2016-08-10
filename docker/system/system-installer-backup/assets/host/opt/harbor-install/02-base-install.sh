#!/bin/sh
# systemctl mask cloud-init cloud-init-local cloud-config cloud-final
# systemctl stop cloud-init cloud-init-local cloud-config cloud-final
systemctl start docker
docker pull docker.io/port/system-installer:latest
docker run \
       --privileged=true \
       -v /:/host \
       -t \
       --net=host \
       docker.io/port/system-installer:latest /init

# harbor-docker pull docker.io/port/system-installer:latest
# harbor-docker  run \
#       --privileged=true \
#       -v /:/host \
#       -t \
#       --net=host \
#       docker.io/port/system-installer:latest /init
rm -f /etc/systemd/system/harbor-etcd.service


#Reload systemd units, remove the inital docker graph directory, and make sure firewalld is not running:
systemctl daemon-reload
systemctl stop docker
rm -rf /var/lib/docker/
systemctl stop firewalld
systemctl disable firewalld
systemctl mask firewalld
systemctl mask rpcbind.service

#Now lets enable passwordless sudo and update the path to include the Harbor Applications:
sed -i 's/%wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tNOPASSWD: ALL/g' /etc/sudoers
export PATH=/usr/local/bin:${PATH}


#Now we can start the harbor-docker daemon, and run the network bootstrap scripts:
ACTION=restart
systemctl ${ACTION} docker-bootstrap
systemctl ${ACTION} harbor-network-bootstrap
systemctl ${ACTION} harbor-ovs
systemctl ${ACTION} harbor-skydns
#Now we can start the harbor-docker daemon, and run the network bootstrap scripts:
ACTION=enable
systemctl ${ACTION} docker-bootstrap
systemctl ${ACTION} harbor-network-bootstrap
systemctl ${ACTION} harbor-ovs
systemctl ${ACTION} harbor-skydns

ACTION=restart
systemctl ${ACTION} harbor-etcd-master
systemctl ${ACTION} docker-bootstrap
systemctl ${ACTION} harbor-ovs
systemctl ${ACTION} docker-ipa
systemctl ${ACTION} harbor-skydns


#Now the base system is up and running we can now update our hosts file to point to the br0, interface that other nodes will connect to:
MASTER_IP=$(ip -f inet -o addr show br0|cut -d\  -f 7 | cut -d/  -f 1)
sed -i "s/127.0.0.1 $(hostname -s).$(hostname -d) $(hostname -s)/${MASTER_IP} $(hostname -s).$(hostname -d) $(hostname -s)/g" /etc/hosts

#Now we can start the harbor-docker daemon, and run the network bootstrap scripts:
ACTION=enable
systemctl ${ACTION} docker-bootstrap
systemctl ${ACTION} harbor-etcd-master
systemctl ${ACTION} harbor-network-bootstrap
systemctl ${ACTION} harbor-ovs
systemctl ${ACTION} docker-ipa
systemctl ${ACTION} harbor-skydns
