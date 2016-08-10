FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="kube-wrapper" \
    IPA_BACKED="False"

RUN yum install -y \
        docker \
        haproxy && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
