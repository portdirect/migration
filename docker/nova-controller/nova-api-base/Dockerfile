FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%nova-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT api-base

RUN yum -y install \
        openstack-nova-api \
        httpd mod_wsgi mod_auth_kerb mod_ssl && \
    rpm -e --nodeps centos-logos && \
    yum clean all && \
    rm -f /etc/httpd/conf.d/*.conf

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf && \
    mkdir -p /var/log/apache2 && \
    chown -R nova:nova /etc/nova
