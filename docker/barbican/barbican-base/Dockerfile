FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-barbican" \
		INIT_DB_REQUIRED="True"

RUN yum install -y \
				openstack-barbican \
				openstack-barbican-keystone-listener \
				openstack-barbican-worker \
				openstack-barbican-api \
				python-ldap3 \
				python-keystonemiddleware \
				pki-base \
				sqlite-devel \
				openldap-devel && \
		yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
