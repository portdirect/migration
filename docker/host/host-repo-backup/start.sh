#!/bin/bash
mkdir -p /var/www/html/repo/images/pxeboot

(
curl -L http://dl.fedoraproject.org/pub/alt/atomic/stable/Cloud_Atomic/x86_64/os/images/pxeboot/vmlinuz > /var/www/html/repo/images/pxeboot/vmlinuz
curl -L http://dl.fedoraproject.org/pub/alt/atomic/stable/Cloud_Atomic/x86_64/os/images/pxeboot/initrd.img > /var/www/html/repo/images/pxeboot/initrd.img
chown -R apache:apache /var/www/html/repo
)&

httpd -DFOREGROUND
