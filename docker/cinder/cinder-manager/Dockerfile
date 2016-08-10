FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%cinder-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="False" \
    INIT_DB_REQUIRED="True" \
    INIT_KEYSTONE_REQUIRED="True"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
