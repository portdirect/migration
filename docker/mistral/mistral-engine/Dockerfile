FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%mistral-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="engine"

RUN yum install -y \
        openstack-mistral-engine \
	  yum clean all

ADD ./start.sh /start.sh
