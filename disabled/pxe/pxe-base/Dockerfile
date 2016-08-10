FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

ENV SECURE_CONFIG False


ENV TFTP_BOOT /var/lib/tftpboot
ENV HTTP_ROOT /usr/share/nginx/html


# Nat router
RUN yum install -y \
        dnsmasq \
        wget \
        iptables && \
    yum clean all && \
    wget --no-check-certificate https://raw.github.com/jpetazzo/pipework/master/pipework && \
    chmod +x pipework

# PXE SERVER INSTALL
RUN yum install -y \
        syslinux \
        tftp-server && \
    yum clean all && \
    cp -r /usr/share/syslinux/* $TFTP_BOOT

# KICKSTART SERVER INSTALL
RUN yum install -y \
        epel-release && \
    yum install -y \
        nginx \
        git && \
    yum clean all

# Make directories
RUN mkdir -p $TFTP_BOOT && \
    mkdir -p $HTTP_ROOT

ADD images.sh /images.sh

RUN chmod +x /images.sh && \
    ./images.sh && \
    rm -f ./images.sh

# KICKSTART SERVER CONFIG
ADD assets/nginx.conf /etc/nginx/nginx.conf



# DHCP
EXPOSE 67/udp
# tftp
EXPOSE 69/udp
# http
EXPOSE 79/tcp


# We run this last to speed the build process
RUN curl -L http://installer.harboros.net:8013/installer/images/images/pxeboot/initrd.img > $TFTP_BOOT/initrd.img && \
    curl -L http://installer.harboros.net:8013/installer/images/images/pxeboot/upgrade.img > $TFTP_BOOT/upgrade.img && \
    curl -L http://installer.harboros.net:8013/installer/images/images/pxeboot/vmlinuz > $TFTP_BOOT/vmlinuz




# PXE SERVER CONFIG
ADD assets/pxelinux.cfg/default $TFTP_BOOT/pxelinux.cfg/default

# Add kickstarts
ADD assets/ks/ $HTTP_ROOT/ks/

# Fix permissions
RUN find $TFTP_BOOT -type d -exec chmod 755 {} \; && \
    find $TFTP_BOOT -type f -exec chmod 755 {} \; && \
    find $HTTP_ROOT -type d -exec chmod 755 {} \; && \
    find $HTTP_ROOT -type f -exec chmod 755 {} \;



ADD start.sh /start.sh
