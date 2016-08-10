FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%swift-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT proxy

RUN yum -y install \
        openstack-swift-proxy \
        openstack-swift-plugin-swift3 \
        httpd \
        mod_wsgi \
        mod_ssl && \
    rpm -e --nodeps centos-logos && \
    rm -f /etc/httpd/conf.d/*.conf && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf && \
    yum clean all && \
    mkdir -p /opt/swift


ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
