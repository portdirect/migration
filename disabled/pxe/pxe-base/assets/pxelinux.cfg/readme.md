label deploy-centos-rpm
menu label Deploy: CentOS: ^RPM
kernel centos7/vmlinuz
append initrd=centos7/initrd.img method=http://mirror.centos.org/centos/7/os/x86_64/ devfs=nomount ip=dhcp net.ifnames=0 biosdevname=0

label deploy-ubuntu-deb
menu label Deploy: Ubuntu: DEB
kernel ubuntu/linux
append initrd=ubuntu/initrd.gz method=http://archive.ubuntu.com/ubuntu/dists/vivid/ devfs=nomount ip=dhcp net.ifnames=0 biosdevname=0



label deploy-rancher
menu label Deploy: Rancher: RAM
kernel rancher/vmlinuz
append initrd=rancher/initrd rancher.state.autoformat=[/dev/sda] rancher.cloud_init.datasources=[url:http://{{ SERVER_IP }}:79/ks/rancher.yaml]
