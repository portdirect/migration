FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%trove-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="False"

RUN yum install -y \
        git \
        openssh && \
    yum clean all && \
    git clone --depth 1 https://github.com/openstack/trove-integration.git /opt/trove-integration

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
