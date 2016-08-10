FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-trove" \
    OPENSTACK_SUBCOMPONENT="image-builder"

RUN yum install -y \
        git \
        sudo \
        parted \
        e2fsprogs \
        diskimage-builder \
        qemu-kvm \
        qemu-img \
        kpartx \
        python-argparse \
        docker \
        which \
        expect && \
    yum clean all

RUN git clone --depth 1 https://git.openstack.org/openstack/diskimage-builder /opt/diskimage-builder && \
    git clone --depth 1 https://git.openstack.org/openstack/dib-utils /opt/dib-utils && \
    git clone --depth 1 https://github.com/openstack/tripleo-image-elements /opt/tripleo-image-elements && \
    git clone --depth 1 https://github.com/openstack/trove-integration.git /opt/trove-integration && \
    git clone --depth 1 https://github.com/openstack/trove.git /opt/trove && \
    git clone --depth 1 https://github.com/openstack/sahara-image-elements.git /opt/sahara-image-elements && \
    git clone --depth 1 https://github.com/openstack/murano-agent.git /opt/murano-agent

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    adduser trove-agent && \
    echo "trove-agent  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chown -R trove-agent:trove-agent /home/trove-agent && \
    chown -R trove-agent:trove-agent /opt && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    chmod 0440 /etc/sudoers
