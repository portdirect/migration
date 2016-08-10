


(

kubectl run --image=nginx --replicas=2 nginx
kubectl run --image=docker.io/port/base:latest --replicas=1 port-testing -- tail -f /dev/null



SVC_NAMESPACE=default
SVC_NETWORK=${SVC_NAMESPACE}-subnet
SVC_NAME=nginx
SVC_PROTO_L7=HTTP
SVC_PROTO=tcp
SVC_ALGO=ROUND_ROBIN
SVC_PORT=80
SVC_EXPOSED_PORT=80



kubectl expose deployment nginx \
--port=${SVC_EXPOSED_PORT} \
--protocol=${SVC_PROTO} \
--name=${SVC_NAME} \
--target-port=${SVC_PORT}


neutron lbaas-loadbalancer-create \
--name="k8s-${SVC_NAME}-lb" \
--provider="haproxy" \
--description="k8s/${SVC_NAMESPACE}/svc/${SVC_NAME}" \
"${SVC_NETWORK}"

neutron lbaas-listener-create \
--name "k8s-${SVC_NAME}-listener" \
--loadbalancer "k8s-${SVC_NAME}-lb" \
--description="k8s/${SVC_NAMESPACE}/svc/${SVC_NAME}" \
--protocol "${SVC_PROTO_L7}" \
--protocol-port "${SVC_EXPOSED_PORT}"


VIP_PORT_ID=$(neutron lbaas-loadbalancer-show "k8s-${SVC_NAME}-lb" -f value -c vip_port_id | tr -cd '[:print:]')
neutron port-update $VIP_PORT_ID --security-group "demo"


neutron lbaas-pool-create \
--name "k8s-${SVC_NAME}-pool" \
--lb-algorithm "${SVC_ALGO}" \
--description="k8s/${SVC_NAMESPACE}/svc/${SVC_NAME}" \
--protocol "${SVC_PROTO_L7}" \
--listener "k8s-${SVC_NAME}-listener" \
--loadbalancer "k8s-${SVC_NAME}-lb"
neutron lbaas-healthmonitor-create \
--name "k8s-${SVC_NAME}-healthmonitor" \
--delay "20" \
--max-retries "10" \
--timeout "1" \
--type "${SVC_PROTO_L7}"  \
--pool "k8s-${SVC_NAME}-pool"


POD_NAME=nginx-3137573019-nf8tb
POD_IP=192.168.0.12

neutron port-update $POD_NAME --security-group "demo"


neutron lbaas-member-create \
--name "k8s-${SVC_NAMESPACE}-${POD_NAME}" \
--weight 100 \
--subnet "${SVC_NETWORK}" \
--address "${POD_IP}" \
--protocol-port "${SVC_PORT}" \
"k8s-${SVC_NAME}-pool"





FIP_ID=$(neutron floatingip-create --port-id ${VIP_PORT_ID} ext-net -f value -c id | tr -cd '[:print:]')
FIP_PORT_ID=$(neutron floatingip-show $FIP_ID -f value -c port_id | tr -cd '[:print:]')
neutron port-update $FIP_PORT_ID --security-group "demo"
FIP_IP=$(neutron floatingip-show $FIP_ID -f value -c floating_ip_address | tr -cd '[:print:]')
curl $FIP_IP
)
