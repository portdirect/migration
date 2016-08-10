FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-swift"

RUN yum -y install \
        openstack-swift \
        python-swiftclient \
        python-ceilometermiddleware \
        python-memcached && \
    yum clean all && \
    mkdir -p /opt/swift

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    chown -R swift:swift /etc/swift
