FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="libvirt" \
    IPA_BACKED="False"

RUN yum -y install \
        centos-release-gluster37 && \
    yum -y install \
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
    curl -L https://download.clearlinux.org/image/OVMF.fd > /usr/share/OVMF/OVMF_CODE.fd

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
