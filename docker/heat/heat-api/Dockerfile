FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%heat-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT api



ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    mkdir -p /var/log/httpd && \
    chown -R 187:187 /etc/heat
