FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%magnum-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="conductor"

RUN yum install -y \
        openstack-magnum-conductor \
	  yum clean all

ADD ./start.sh /start.sh
