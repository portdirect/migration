FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-mistral" \
    INIT_DB_REQUIRED="True" \
    OPENSTACK_SUBCOMPONENT="base"

RUN yum install -y \
        openstack-mistral-all \
        openstack-mistral-api \
        openstack-mistral-common \
        openstack-mistral-engine \
        openstack-mistral-executor \
        python-mistralclient \
	  yum clean all


ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
