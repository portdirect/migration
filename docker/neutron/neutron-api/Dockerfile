FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%neutron-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT api

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    chown -R neutron:neutron /etc/neutron
