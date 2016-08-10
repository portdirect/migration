


(



nova boot \
--flavor="m1.tiny" \
--image="ewindisch/cirros:latest" \
--nic="net-name=admin,v4-fixed-ip=10.63.0.10" \
--security-group "demo" \
"demo-cirros"

nova boot \
--flavor="m1.tiny" \
--image="docker.io/nginx:latest" \
--nic="net-name=admin,v4-fixed-ip=10.63.0.11" \
--security-group "demo" \
"demo-nginx-1"
nova boot \
--flavor="m1.tiny" \
--image="docker.io/nginx:latest" \
--nic="net-name=admin,v4-fixed-ip=10.63.0.12" \
--security-group "demo" \
"demo-nginx-2"

neutron lbaas-loadbalancer-create --name "demo-nginx-lb" --provider haproxy "int-subnet"
neutron lbaas-listener-create \
--name "demo-nginx-listener" \
--loadbalancer "demo-nginx-lb" \
--protocol "HTTP" \
--protocol-port "80"

sleep 20s
neutron lbaas-pool-create \
--name "demo-nginx-pool" \
--lb-algorithm "ROUND_ROBIN" \
--protocol "HTTP" \
--listener "demo-nginx-listener" \
--loadbalancer "demo-nginx-lb"

sleep 20s
neutron lbaas-member-create \
--name "demo-nginx" \
--weight 100 \
--subnet int-subnet \
--address 203.0.115.10 \
--protocol-port 80 \
"demo-nginx-pool"

neutron lbaas-healthmonitor-create \
--name "demo-nginx" \
--delay 20 \
--max-retries 10 \
--timeout 1 \
--type HTTP \
--pool "demo-nginx-pool"


VIP_PORT_ID=$(neutron lbaas-loadbalancer-show demo-nginx-lb -f value -c vip_port_id | tr -cd '[:print:]' )
neutron port-update $VIP_PORT_ID --security-group "demo"


FIP_ID=$(neutron floatingip-create --port-id ${VIP_PORT_ID} ext-net -f value -c id | tr -cd '[:print:]' )
FIP_PORT_ID=$(neutron floatingip-show $FIP_ID -f value -c port_id | tr -cd '[:print:]')

neutron port-update $FIP_PORT_ID --security-group "demo"
FIP_PORT_IP=$(neutron floatingip-show $FIP_ID -f value -c floating_ip_address | tr -cd '[:print:]')
echo ${FIP_PORT_IP}
sleep 10s
curl ${FIP_PORT_IP}
)
