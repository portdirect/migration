FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="kube-wrapper" \
    IPA_BACKED="False"

RUN yum install -y \
        docker \
        bridge-utils \
        openvswitch \
        haproxy && \
    yum clean all && \
    curl -L https://raw.github.com/jpetazzo/pipework/master/pipework > /usr/bin/pipework && \
    chmod +x /usr/bin/pipework

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
