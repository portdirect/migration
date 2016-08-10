FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%swift-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="container-server"

RUN yum -y install \
        openstack-swift-container && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
