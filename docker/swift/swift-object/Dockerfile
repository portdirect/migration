FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%swift-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="object"

RUN yum -y install \
        openstack-swift-object && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
