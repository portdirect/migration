FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%magnum-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="True"

RUN yum install -y \
        bzip2 \
        openssh && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
