FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%glance-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="registry"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    mkdir -p /var/log/httpd && \
    chown -R glance:glance /etc/glance
