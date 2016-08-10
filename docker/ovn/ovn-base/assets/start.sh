#!/bin/bash

echo "Container is monitoring /dev/null to stay alive"
tail -f /dev/null


modprobe vport_geneve
modprobe geneve
modprobe openvswitch
#ovn-controller
(
docker stop ovn-controller ovsdb-server ovs-vswitchd ovn-northd ovn-nb ovn-sb ovs-init etcd kube kube-controller kube-scheduler
docker rm -v ovn-controller ovsdb-server ovs-vswitchd ovn-northd ovn-nb ovn-sb ovs-init etcd kube kube-controller kube-scheduler
rm -rf /var/run/openvswitch
rm -rf /var/lib/openvswitch

docker pull port/ovn-controller:latest
docker pull port/ovsdb-server:latest
docker pull port/ovs-vswitchd:latest
docker pull port/ovn-northd:latest
docker pull port/ovn-nb:latest
docker pull port/ovn-sb:latest
docker pull port/ovs-init:latest
docker pull port/ovn-kube:latest
docker pull port/system-etcd:latest
)

echo "10.132.0.2 master" >> /etc/hosts
echo "10.132.0.3 node" >> /etc/hosts

systemctl start docker
docker run --name etcd -d  --net=host port/system-etcd:latest etcd --advertise-client-urls 'http://master:4001' \
--listen-client-urls 'http://localhost:2379,http://0.0.0.0:4001'


docker pull port/ovs:latest
docker rm openvswitch
docker run \
--pid=host \
--name=openvswitch \
--net=host -t -d \
--privileged \
-v /dev/net:/dev/net:rw \
-v /var/run:/var/run:rw \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
-v /var/lib/openvswitch:/var/lib/openvswitch:rw \
port/ovn-base:latest tail -f /dev/null

docker exec -it openvswitch bash

 ovs-vsctl show

rmmod openvswitch
modprobe libcrc32c
modprobe nf_conntrack_ipv6
modprobe nf_nat_ipv6
modprobe gre
insmod /opt/ovs/kernel-modules/openvswitch.ko
insmod /opt/ovs/kernel-modules/vport-geneve.ko


# Start OVS
/usr/share/openvswitch/scripts/ovs-ctl restart --system-id="$(echo $(hostname -s) | sed 's/^node-//' )"



OVS_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
MASTER_IP=10.132.0.2
(
UUID="$(hostname -s | sed 's/^node-//')"
docker exec openvswitch ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:${MASTER_IP}:6642"
docker exec openvswitch ovs-vsctl set Open_vSwitch . external_ids:ovn-nb="tcp:${MASTER_IP}:6641"
docker exec openvswitch ovs-vsctl set Open_vSwitch . external_ids:ovn-encap-ip=${OVS_IP}
docker exec openvswitch ovs-vsctl set Open_vSwitch . external_ids:ovn-encap-type="geneve"
docker exec openvswitch ovs-vsctl set Open_vSwitch . external_ids:system-id="${UUID}"
docker exec openvswitch ovs-vsctl set Open_vSwitch . external_ids:hostname="$(hostname)"
docker exec openvswitch ovs-vsctl set Open_vSwitch . external_ids:ovn-chassis-id="${UUID}"
docker exec openvswitch /usr/share/openvswitch/scripts/ovs-ctl restart --system-id=${UUID}
docker exec openvswitch /usr/share/openvswitch/scripts/ovn-ctl restart_controller
)



docker pull port/ovn-northd:latest
docker stop ovn-northd
docker rm ovn-northd
docker run \
--name=ovn-northd \
--net=host -d \
--privileged \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
-v /var/lib/openvswitch:/var/lib/openvswitch:rw \
port/ovn-northd:latest





















docker run --name kube -d \
--net=host \
port/system-kube:latest \
/hyperkube apiserver \
--service-cluster-ip-range=192.168.0.1/24 \
--etcd-servers=http://127.0.0.1:4001 \
--insecure-bind-address=0.0.0.0  --v=3 --runtime-config="extensions/v1beta1=true" --runtime-config="extensions/v1beta1/thirdpartyresources=true"
docker run --name kube-controller -d \
--net=host \
port/system-kube:latest \
/hyperkube controller-manager
docker run --name kube-scheduler -d \
--net=host \
port/system-kube:latest \
/hyperkube scheduler --master=http://127.0.0.1:8080




















docker exec -it kube bash


cat > network_policy.yaml <<EOF
metadata:
  name: "network-policy.experimental.kubernetes.io"
apiVersion: "extensions/v1beta1"
kind: "ThirdPartyResource"
description: "An experimental specification of network policy"
versions:
  - name: v1
EOF
kubectl create -f network_policy.yaml --validate=False

cat > sample_policy_1.json <<EOF
{"kind": "NetworkPolicy",
 "apiVersion": "experimental.kubernetes.io/v1",
 "metadata":
   {"name": "sample_policy_1"},
 "ingress":
  [
    {"ports":
      [
        { "protocol": "TCP",
          "port": "80"}
      ]
    }
  ],
"egress":
 [
   {"ports":
     [
       { "protocol": "TCP",
         "port": "80"}
     ]
   }
 ]
}
EOF
curl -X POST -H "Content-Type: application/json" -d @sample_policy_1.json \
 http://localhost:8080/apis/experimental.kubernetes.io/v1/namespaces/default/networkpolicys



docker run \
--name=ovs-init \
--net=host -t -d \
--privileged \
-e OVN_SB_REMOTE=10.132.0.2 \
-e HOST_IP=10.132.0.3 \
-v /dev/net:/dev/net:rw \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
-v /var/lib/openvswitch:/var/lib/openvswitch:rw \
port/ovs-init:latest




docker run \
--pid=host \
--name=ovsdb-server \
--net=host -t -d \
--privileged \
-v /dev/net:/dev/net:rw \
-v /var/run:/var/run:rw \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
-v /var/lib/openvswitch:/var/lib/openvswitch:rw \
port/ovsdb-server:latest

CENTRAL_IP=10.132.0.2
LOCAL_IP=10.132.0.2
ENCAP_TYPE=geneve
docker exec -it ovsdb-server ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$CENTRAL_IP:6642" \
  external_ids:ovn-nb="tcp:$CENTRAL_IP:6641" external_ids:ovn-encap-ip=$LOCAL_IP external_ids:ovn-encap-type="$ENCAP_TYPE"


docker run \
--pid=host \
--name=ovs-vswitchd \
--net=host -t -d \
--privileged \
-v /dev/net:/dev/net:rw \
-v /var/run:/var/run:rw \
-v /var/lib/openvswitch:/var/lib/openvswitch:rw \
port/ovs-vswitchd:latest












docker run \
--name=kube \
--pid=host
--net=host -ti --rm  \
--privileged \
-v /dev/net:/dev/net:rw \
-v /var/run:/var/run:rw \
-v /var/run/openvswitch:/var/run/openvswitch:rw \
-v /var/lib/openvswitch:/var/lib/openvswitch:rw \
port/ovn-kube:latest bash




















mkdir -p $base_dir

LOGDIR=/var/lib/log
mkdir -p $LOGDIR
for db in conf.db ovnsb.db ovnnb.db vtep.db ; do
    if [ -f $base_dir/$db ] ; then
        rm -f $base_dir/$db
    fi
done
rm -f $base_dir/.*.db.~lock~



echo "Creating OVS, OVN-Southbound and OVN-Northbound Databases"
ls /var/run/openvswitch/conf.db || ovsdb-tool create /var/run/openvswitch/conf.db /opt/ovs/vswitchd/vswitch.ovsschema


if true ; then
    ls /var/run/openvswitch/ovnsb.db || ovsdb-tool create /var/run/openvswitch/ovnsb.db /opt/ovs/ovn/ovn-sb.ovsschema
    ls /var/run/openvswitch/ovnnb.db || ovsdb-tool create /var/run/openvswitch/ovnnb.db /opt/ovs/ovn/ovn-nb.ovsschema
fi




ovsdb-server \
--remote=punix:/var/run/openvswitch/ovnnb_db.sock \
--remote=ptcp:6641:0.0.0.0 \
--pidfile=/var/run/openvswitch/ovnnb_db.pid \
--unixctl=ovnnb_db.ctl \
/var/lib/openvswitch/ovnnb.db

ovsdb-server \
--remote=punix:/var/run/openvswitch/ovnsb_db.sock \
--remote=ptcp:6642:0.0.0.0 \
--pidfile=/var/run/openvswitch/ovnsb_db.pid \
--unixctl=ovnsb_db.ctl \
/var/lib/openvswitch/ovnsb.db

    /usr/share/openvswitch/scripts/ovn-ctl start_ovsdb \
          --db-nb-port=$DB_NB_PORT --db-sb-port=$DB_SB_PORT \
          --db-nb-file=$DB_NB_FILE --ovn-nb-logfile=$OVN_NB_LOGFILE \
          --db-sb-file=$DB_SB_FILE --ovn-sb-logfile=$OVN_SB_LOGFILE
fi





if is_ovn_service_enabled ovn-controller || is_ovn_service_enabled ovn-controller-vtep ; then
    local _OVSREMOTE="--remote=db:Open_vSwitch,Open_vSwitch,manager_options"
    local _VTEPREMOTE=""
    local _OVSDB=conf.db
    local _VTEPDB=""


    ovsdb-server --remote=punix:/var/run/openvswitch/db.sock \
                 $_OVSREMOTE $_VTEPREMOTE \
                 -vconsole:off \
                 --log-file=$LOGDIR/ovsdb-server.log \
                 $_OVSDB $_VTEPDB

    echo -n "Waiting for ovsdb-server to start ... "
    local testcmd="test -e /usr/local/var/run/openvswitch/db.sock"
    test_with_retry "$testcmd" "ovsdb-server did not start" $SERVICE_TIMEOUT 1
    echo "done."
    ovs-vsctl --no-wait init
    ovs-vsctl --no-wait set open_vswitch . system-type="devstack"
    ovs-vsctl --no-wait set open_vswitch . external-ids:system-id="$OVN_UUID"
fi

if is_ovn_service_enabled ovn-controller || is_ovn_service_enabled ovn-controller-vtep ; then
    ovs-vsctl --no-wait set open_vswitch . external-ids:ovn-remote="$OVN_SB_REMOTE"
    ovs-vsctl --no-wait set open_vswitch . external-ids:ovn-bridge="br-int"
    ovs-vsctl --no-wait set open_vswitch . external-ids:ovn-encap-type="geneve"
    ovs-vsctl --no-wait set open_vswitch . external-ids:ovn-encap-ip="$HOST_IP"

    ovn_base_setup_bridge br-int
    ovs-vsctl --no-wait set bridge br-int fail-mode=secure other-config:disable-in-band=true

    local ovswd_logfile="ovs-switchd.log.${CURRENT_LOG_TIME}"
    bash -c "cd '$LOGDIR' && touch '$ovswd_logfile' && ln -sf '$ovswd_logfile' ovs-vswitchd.log"

    # Bump up the max number of open files ovs-vswitchd can have
    sudo sh -c "ulimit -n 32000 && exec ovs-vswitchd --pidfile --detach -vconsole:off --log-file=$LOGDIR/ovs-vswitchd.log"

    if is_provider_network; then
        ovn_base_setup_bridge $OVS_PHYSICAL_BRIDGE
        ovs-vsctl set open . external-ids:ovn-bridge-mappings=${PHYSICAL_NETWORK}:${OVS_PHYSICAL_BRIDGE}
    fi
fi
