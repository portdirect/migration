FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%mistral-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="api"

RUN yum install -y \
        openstack-mistral-api && \
	  yum clean all

ADD ./start.sh /start.sh
