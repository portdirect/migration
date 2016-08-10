FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ceilometer-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="notification"

RUN yum install -y \
				openstack-ceilometer-notification && \
		yum clean all

ADD ./start.sh /start.sh
