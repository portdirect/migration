FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%

RUN apk update && \
    apk upgrade && \
    apk add --update \
        ca-certificates \
        openssl \
        tar \
        dnsmasq \
        syslinux \
        sipcalc \
        iptables && \
    wget https://github.com/coreos/etcd/releases/download/v2.0.10/etcd-v2.0.10-linux-amd64.tar.gz && \
    tar xzvf etcd-v2.0.10-linux-amd64.tar.gz && \
    mv etcd-v2.0.10-linux-amd64/etcdctl /bin/ && \
    apk del --purge \
        tar \
        openssl \
        ca-certificates && \
    rm -Rf etcd-v2.0.10-linux-amd64* && \
    rm -Rf var/cache/apk/* && \
    adduser pxemanager -D -H -s /dev/null

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    rm -rf /opt/harbor/assets/container && \
    chmod +x /init /bin/*

ADD http://installer.harboros.net:8013/installer/images/images/pxeboot/initrd.img /usr/share/syslinux/initrd.img
ADD http://installer.harboros.net:8013/installer/images/images/pxeboot/upgrade.img /usr/share/syslinux/upgrade.img
ADD http://installer.harboros.net:8013/installer/images/images/pxeboot/vmlinuz /usr/share/syslinux/vmlinuz

CMD ["/init"]
