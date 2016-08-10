FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="accounts" \
    OPENSTACK_SUBCOMPONENT="activate" \
    IPA_BACKED="True"

RUN yum install -y \
        ssmtp \
        mutt && \
    yum clean all


ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
