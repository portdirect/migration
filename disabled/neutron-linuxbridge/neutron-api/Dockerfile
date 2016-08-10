FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%neutron-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT api

RUN yum install -y \
        openstack-neutron \
        python-neutronclient \
        which \
        httpd mod_wsgi mod_auth_kerb mod_ssl && \
    rpm -e --nodeps centos-logos && \
    yum clean all && \
    rm -f /etc/httpd/conf.d/*.conf

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf && \
    mkdir -p /var/log/httpd && \
    chown -R neutron:neutron /etc/neutron
