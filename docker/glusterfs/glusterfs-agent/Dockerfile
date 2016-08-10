FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="glusterfs" \
    OPENSTACK_SUBCOMPONENT="agent"

RUN yum --setopt=tsflags=nodocs -y install \
        centos-release-gluster37 && \
    yum update -y && \
    yum --setopt=tsflags=nodocs -y install \
        xfsprogs \
        glusterfs-server \
        etcd \
        bind-utils && \
    yum clean all

ADD ./start.sh /start.sh
