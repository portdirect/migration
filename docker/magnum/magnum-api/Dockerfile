FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%magnum-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="api"

RUN yum install -y \
        openstack-magnum-api && \
	  yum clean all

ADD ./start.sh /start.sh
