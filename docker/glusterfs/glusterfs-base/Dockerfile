FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base-minimal:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="glusterfs" \
    OPENSTACK_SUBCOMPONENT="base"

RUN yum --setopt=tsflags=nodocs -y install \
        xfsprogs \
        glusterfs-server \
        glusterfs-api \
        glusterfs-geo-replication \
        glusterfs-extra-xlators \
        glusterfs-coreutils \
        glusterfs-ganesha \
        etcd \
        bind-utils \
        parted \
        nfs-ganesha-gluster \
        python-pip \
        parted \
        lvm2 && \
    yum clean all && \
    pip install --upgrade pip && \
    pip install supervisor &&  \
    pip install supervisor-stdout && \
    mkdir -p /var/log/supervisor && \
    sed -i "s|udev_rules = 1|udev_rules = 0|g" /etc/lvm/lvm.conf &&  \
    sed -i "s|udev_sync = 1|udev_sync = 0|g" /etc/lvm/lvm.conf

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
CMD ["/init"]
