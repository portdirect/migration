FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-keystone" \
    IPA_BACKED="True" \
    INIT_DB_REQUIRED="True"

ADD ./assets/etc/yum.repos.d/infrastructure7-testing.repo /etc/yum.repos.d/infrastructure7-testing.repo
#curl -o /etc/yum.repos.d/security:shibboleth.repo http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo && \
RUN yum update -y && \
    yum upgrade -y && \
    yum install -y \
        openstack-keystone \
        python-keystoneclient \
        python-openstackclient \
        httpd \
        mod_ssl \
        mod_wsgi \
        mod_auth_mellon \
        ipsilon-client \
        openldap-clients \
        sssd-dbus && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf && \
    chown -R keystone:keystone /etc/keystone && \
    chown -R keystone:keystone /var/log/keystone
