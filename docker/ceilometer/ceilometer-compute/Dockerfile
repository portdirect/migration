FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ceilometer-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="compute"

RUN yum install -y \
        openstack-ceilometer-compute \
        python-ceilometerclient \
        python-pecan && \
    yum clean all

ADD ./start.sh /start.sh
