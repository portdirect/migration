FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%mistral-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="executor"

RUN yum install -y \
        openstack-mistral-executor \
	  yum clean all

ADD ./start.sh /start.sh
