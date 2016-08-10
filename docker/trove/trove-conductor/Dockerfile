FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%trove-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="conductor"

RUN yum install -y \
        openstack-trove-conductor && \
	  yum clean all

ADD ./start.sh /start.sh
