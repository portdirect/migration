FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%manila-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="api"

RUN yum install -y \
        openstack-manila && \
	  yum clean all

ADD ./start.sh /start.sh
