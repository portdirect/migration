FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ipsilon-proxy:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="grafana" \
    IPA_BACKED="False"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    chown -R apache:apache /var/www/html
