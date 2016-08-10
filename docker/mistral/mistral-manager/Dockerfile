FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%mistral-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="True"

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
