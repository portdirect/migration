FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%

RUN yum -y install openstack-nova-compute \
        sysfsutils && yum clean all

ADD config-nova-compute.sh /opt/harbor/config-nova-compute.sh

ADD ./start.sh /start.sh
