FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%manila-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="False"

RUN yum install -y \
        openssh && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
