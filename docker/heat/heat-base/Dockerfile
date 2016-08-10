FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-heat" \
		INIT_DB_REQUIRED="True"

RUN yum install -y \
				openstack-heat-* \
        httpd \
        mod_wsgi \
        mod_auth_kerb \
        mod_ssl && \
    rpm -e --nodeps centos-logos && \
    yum clean all && \
    rm -f /etc/httpd/conf.d/*.conf && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
