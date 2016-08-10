FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%keystone-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT api

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    chown keystone:keystone  /etc/keystone/sso_callback_template.html
