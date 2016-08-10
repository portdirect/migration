FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-compute-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="compute" \
    IPA_BACKED="False"

RUN yum -y install \
        openstack-nova-compute \
        spice-html5 \
        python-barbicanclient \
        glusterfs \
        glusterfs-fuse \
        libvirt-daemon \
        libguestfs \
        qemu-system-x86 \
        libvirt-daemon-driver-nwfilter \
        libvirt-daemon-config-nwfilter \
        libvirt-daemon-driver-lxc && \
    yum clean all && \
    mkdir -p /usr/share/OVMF && \
    curl -L https://download.clearlinux.org/image/OVMF.fd > /usr/share/OVMF/OVMF_CODE.fd && \
    yum clean all && \
    mkdir -p /var/log/nova && \
    chown -R nova /var/log/nova

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
