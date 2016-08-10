#!/bin/bash
while true
do
	echo "Watching etcd for updates: /ovs/network/subnets"
	etcdctl exec-watch --recursive  /ovs/network/subnets -- /bin/update-ovs
done
