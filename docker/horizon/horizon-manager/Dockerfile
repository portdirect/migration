FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%horizon-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="False" \
    INIT_DB_REQUIRED="False"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    yum install -y \
        docker && \
    yum clean all
