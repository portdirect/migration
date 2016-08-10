FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%keystone-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT manager
ENV OPENSTACK_COMPONENT="os-keystone" \
    IPA_BACKED="True" \
    INIT_DB_REQUIRED="False"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    yum install -y \
        docker && \
    yum clean all
