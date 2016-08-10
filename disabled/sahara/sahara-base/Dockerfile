FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%

RUN yum -y install \
        openstack-sahara \
        MySQL-python && \
    yum clean all

ADD sahara-common.sh /opt/harbor/sahara-common.sh
RUN chmod +x /opt/harbor/sahara-common.sh
