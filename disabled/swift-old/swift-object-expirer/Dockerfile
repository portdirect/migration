FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%swift-object-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT object-expirer

RUN yum -y install \
        openstack-swift-proxy \
        openstack-swift-container \
    && yum clean all

COPY start.sh /
