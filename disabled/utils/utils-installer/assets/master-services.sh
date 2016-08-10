#!/bin/sh

(
systemctl stop docker
systemctl stop etcd || systemctl stop etcd
systemctl stop etcd
systemctl stop docker-bootstrap
cat > /etc/etcd/etcd.env <<EOF
ETCD_DEV=br0
ETCD_DISCOVERY_TOKEN={{MASTER_ETCD_DISCOVERY_TOKEN}}
ETCD_INITIAL_NODES=1
EOF
rm -rf /var/lib/etcd/*
rm -rf /var/lib/ipa-data/*
rm -rf /var/lib/os-database/*
rm -rf /var/lib/docker-bootstrap/*
)


export SYS_ROOT=''
export ROLE=master

./common-os.sh
./common-cockpit.sh
./common-etcd.sh
./common-skydns.sh
#./common-flanneld.sh
./common-docker.sh
./common-ovs.sh
./common-kubernetes.sh


./master-pxe.sh

./common-swarm.sh


systemctl daemon-reload

action=restart



systemctl mask docker.socket
systemctl ${action} docker-bootstrap
systemctl ${action} etcd
systemctl ${action} ovs
systemctl ${action} docker

systemctl ${action} skydns-reset
systemctl ${action} skydns-preflight
systemctl ${action} skydns
systemctl ${action} skydns-freeipa


systemctl ${action} swarm
systemctl ${action} swarm-api

systemctl ${action} harbor-sysinfo
systemctl ${action} harbor-update.path



































./master-freeipa.sh


./master-os-glusterfs.sh

./master-os-database.sh
./master-os-messaging.sh
./master-os-keystone.sh
./master-os-glance.sh
./master-os-neutron.sh
./master-os-nova.sh
./master-os-horizon.sh
./master-os-heat.sh
./master-os-swift.sh
./master-os-cinder.sh
./master-os-barbican.sh

systemctl restart os-barbican-manager
systemctl restart os-barbican-api

#./master-os-gitlab.sh

systemctl daemon-reload

systemctl stop docker




action=disable
systemctl ${action} skydns-reset
systemctl ${action} skydns-preflight
systemctl ${action} skydns
systemctl ${action} skydns-freeipa

systemctl ${action} docker-manager
systemctl ${action} docker


systemctl ${action} cockpit

systemctl ${action} freeipa
systemctl ${action} pxe
systemctl ${action} os-neutron-router



systemctl ${action} docker-swarm-manager
systemctl ${action} docker-swarm
systemctl ${action} docker-swarm-api


systemctl ${action} harbor-mounter.path



(
systemctl ${action} kubernetes-manager
systemctl ${action} kubelet
systemctl ${action} kube-apiserver
systemctl ${action} kube-controller-manager

systemctl ${action} kube-scheduler
systemctl ${action} kubernetes-skydns
systemctl ${action} kube-proxy
)












action=disable






action=restart

(
systemctl ${action} os-glusterfs
)







action=disable

systemctl ${action} os-database

systemctl ${action} os-messaging





systemctl ${action} os-keystone-manager
systemctl ${action} os-keystone-api





action=disable
systemctl ${action} os-swift-manager
systemctl ${action} os-swift-proxy
systemctl ${action} os-swift-storage



KUBE_NODE=master.port.direct
/usr/local/bin/kubectl label --overwrite node $KUBE_NODE cinder-storage=true
#/usr/local/bin/kubectl label --overwrite node $KUBE_NODE cinder-backup=true

systemctl ${action} os-cinder-manager
systemctl ${action} os-cinder-api
systemctl ${action} os-cinder-storage




systemctl ${action} os-glance-manager
systemctl ${action} os-glance-api



(
KUBE_NODES=$(kubectl get nodes --no-headers| awk -F ' ' '{print $1}')
for KUBE_NODE in $KUBE_NODES
do
  /usr/local/bin/kubectl label --overwrite node $KUBE_NODE neutron-agent=true
done
KUBE_NODE=master.port.direct
/usr/local/bin/kubectl label --overwrite node $KUBE_NODE neutron-services=true

systemctl ${action} os-neutron-manager
systemctl ${action} os-neutron-api
systemctl ${action} os-neutron-agent
systemctl ${action} os-neutron-services
systemctl ${action} os-neutron-router
)
(
KUBE_NODE=master.port.direct
/usr/local/bin/kubectl label --overwrite node $KUBE_NODE nova-novncproxy=true


systemctl ${action} os-nova-manager
systemctl ${action} os-nova-api
systemctl ${action} os-nova-services

KUBE_NODES=$(kubectl get nodes --no-headers| awk -F ' ' '{print $1}')
for KUBE_NODE in $KUBE_NODES
do
  /usr/local/bin/kubectl label --overwrite node $KUBE_NODE nova-compute='libvirt'
done
systemctl ${action} os-nova-compute

systemctl ${action} os-horizon-manager
systemctl ${action} os-horizon-api
)
)


systemctl ${action} os-heat-manager
systemctl ${action} os-heat-api
systemctl ${action} os-heat-services
)

# systemctl ${action} os-gitlab-manager
# systemctl ${action} os-gitlab-db
# systemctl ${action} os-gitlab-redis
# systemctl ${action} os-gitlab-api




systemctl ${action} os-murano-manager
systemctl ${action} os-murano-api
systemctl ${action} os-murano-services



action=stop
