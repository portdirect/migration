FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-api-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT metadata-api

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    chown -R nova:nova /var/www/cgi-bin/nova && \
    mkdir -p /var/log/apache2 && \
    chown -R nova:nova /etc/nova
