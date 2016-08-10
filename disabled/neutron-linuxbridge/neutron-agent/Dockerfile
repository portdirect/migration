FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%neutron-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT agent

# Install required packages
RUN yum install -y \
        openstack-neutron \
        openstack-neutron-linuxbridge \
        net-tools \
        ebtables && \
    yum clean all

ADD ./start.sh /start.sh
