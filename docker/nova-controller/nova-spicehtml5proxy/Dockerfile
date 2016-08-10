FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT spicehtml5-proxy

RUN yum -y install \
        spice-html5 \
        openstack-nova-spicehtml5proxy \
        numpy && \
    yum clean all

ADD assets/spice.css /usr/share/spice-html5/spice.css

ADD start.sh /start.sh
