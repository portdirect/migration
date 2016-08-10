FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%trove-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="api"

RUN yum install -y \
        openstack-trove-api && \
	  yum clean all

ADD ./start.sh /start.sh
