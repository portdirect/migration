#ETCD

MODULE=kubernetes

mkdir -p ${SYS_ROOT}/etc/${MODULE}/
cp -rf ./assets/${MODULE}/etc/* ${SYS_ROOT}/etc/${MODULE}/

mkdir -p ${SYS_ROOT}/var/usrlocal/bin/
chmod +x ./assets/${MODULE}/bin/*
cp -rf ./assets/${MODULE}/bin/* ${SYS_ROOT}/var/usrlocal/bin/

cp ./assets/${MODULE}/*.service ${SYS_ROOT}/etc/systemd/system/
