FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%designate-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="pdns"

RUN yum install -y \
        pdns \
        pdns-backend-mysql \
        bind-utils && \
	  yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
