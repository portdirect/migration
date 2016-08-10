FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-keystone" \
    IPA_BACKED="True" \
    INIT_DB_REQUIRED="True"

#Install required packages
RUN yum install -y \
        openstack-keystone \
        python-keystoneclient \
        python-openstackclient \
        httpd mod_wsgi mod_auth_kerb mod_ssl \
        openldap-clients && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf && \
    ln /var/www/cgi-bin/keystone/keystone.py /var/www/cgi-bin/keystone/main && \
    ln /var/www/cgi-bin/keystone/keystone.py /var/www/cgi-bin/keystone/admin && \
    chown -R keystone:keystone /var/www/cgi-bin/keystone && \
    mkdir -p /var/log/apache2 && \
    chown -R keystone:keystone /etc/keystone
