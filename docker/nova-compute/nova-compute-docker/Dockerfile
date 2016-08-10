FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-compute-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="compute-docker" \
    IPA_BACKED="False"

RUN yum -y install \
        docker-engine && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
