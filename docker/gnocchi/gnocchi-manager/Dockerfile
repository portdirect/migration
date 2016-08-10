FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%gnocchi-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="manager" \
    IPA_BACKED="False"

ADD ./assets/etc/yum.repos.d/infrastructure7-testing.repo /etc/yum.repos.d/infrastructure7-testing.repo

RUN yum install -y \
				ipsilon-client && \
		yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
