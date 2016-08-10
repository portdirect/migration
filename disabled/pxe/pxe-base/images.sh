#!/bin/bash
echo "getting pxe boot images"

echo "DBan"
mkdir -p $TFTP_BOOT/dban
curl -L http://git2.cannycomputing.com/user/installer/raw/master/assets/dban/dban.bzi > $TFTP_BOOT/dban/dban.bzi

# echo "Centos7"
# mkdir -p $TFTP_BOOT/centos7
# curl -L http://mirrors.ukfast.co.uk/sites/ftp.centos.org/7/os/x86_64/images/pxeboot/initrd.img > $TFTP_BOOT/centos7/initrd.img
# curl -L http://mirrors.ukfast.co.uk/sites/ftp.centos.org/7/os/x86_64/images/pxeboot/upgrade.img > $TFTP_BOOT/centos7/upgrade.img
# curl -L http://mirrors.ukfast.co.uk/sites/ftp.centos.org/7/os/x86_64/images/pxeboot/vmlinuz > $TFTP_BOOT/centos7/vmlinuz
#
#
# echo "Ubuntu 15.04"
# mkdir -p $TFTP_BOOT/ubuntu
# curl -L http://archive.ubuntu.com/ubuntu/dists/vivid/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/initrd.gz > $TFTP_BOOT/ubuntu/initrd.gz
# curl -L http://archive.ubuntu.com/ubuntu/dists/vivid/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/linux > $TFTP_BOOT/ubuntu/linux
#
#
# echo "RancherOS"
# mkdir -p $TFTP_BOOT/rancher
# curl -L http://releases.rancher.com/os/latest/initrd > $TFTP_BOOT/rancher/initrd
# curl -L http://releases.rancher.com/os/latest/vmlinuz > $TFTP_BOOT/rancher/vmlinuz
