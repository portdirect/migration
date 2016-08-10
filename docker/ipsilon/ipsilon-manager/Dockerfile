FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ipsilon-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="server" \
    IPA_BACKED="False"


ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    yum install -y \
        docker && \
    yum clean all
