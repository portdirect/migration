FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ceilometer-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="central"

RUN yum install -y \
				openstack-ceilometer-central && \
		yum clean all

ADD ./start.sh /start.sh
