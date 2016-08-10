FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-neutron" \
    INIT_DB_REQUIRED="True"

RUN yum install -y \
        openstack-neutron \
        openstack-neutron-ml2 \
        python-barbicanclient \
        openstack-neutron-lbaas \
        tcpdump && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
