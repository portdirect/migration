FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="image-builder"

RUN yum install -y \
        git \
        diskimage-builder \
        which \
        python-pip \
        sudo \
        parted \
        e2fsprogs \
        xfsprogs && \
    yum clean all && \
    mkdir -p /opt/openstack-diskimage-builder && \
    git clone --depth 1 https://git.openstack.org/openstack/diskimage-builder.git /opt/openstack-diskimage-builder/diskimage-builder && \
    pip install --upgrade /opt/openstack-diskimage-builder/diskimage-builder && \
    git clone --depth 1 https://git.openstack.org/openstack/tripleo-image-elements.git /opt/openstack-diskimage-builder/tripleo-image-elements && \
    git clone --depth 1 https://git.openstack.org/openstack/heat-templates.git /opt/openstack-diskimage-builder/heat-templates && \
    git clone --depth 1 https://git.openstack.org/openstack/dib-utils.git /opt/openstack-diskimage-builder/dib-utils && \
    git clone --depth 1 https://git.openstack.org/openstack/murano /opt/openstack-diskimage-builder/murano && \
    git clone --depth 1 https://git.openstack.org/openstack/murano-agent /opt/openstack-diskimage-builder/murano-agent && \
    git clone --depth 1 https://github.com/openstack/murano-apps.git /opt/openstack-diskimage-builder/murano-apps

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    chmod 0440 /etc/sudoers
