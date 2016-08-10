FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT os-ceilometer

RUN yum -y install \
        openstack-ceilometer-common \
        mongodb \
        python-oslo-db \
        python-tooz && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
