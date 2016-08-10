FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-keystone" \
    IPA_BACKED="True" \
    INIT_DB_REQUIRED="True"

ADD ./assets/etc/yum.repos.d/infrastructure7-testing.repo /etc/yum.repos.d/infrastructure7-testing.repo

RUN yum update -y && \
    yum upgrade -y && \
    yum install -y \
        openstack-keystone \
        python-keystoneclient \
        python-openstackclient \
        httpd \
        mod_ssl \
        mod_wsgi \
        mod_auth_gssapi \
        mod_lookup_identity \
        mod_auth_mellon \
        ipsilon-client \
        openldap-clients \
        sssd-dbus && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    sed -i 's/^Listen 80/#Listen 80/' /etc/httpd/conf/httpd.conf && \
    mkdir -p /var/log/apache2 && \
    chown -R keystone:keystone /etc/keystone && \
    ln -s /etc/httpd/conf.modules.d/10-auth_mellon.conf /etc/httpd/conf.d/10-auth_mellon.conf && \
    ln -s /etc/httpd/conf.modules.d/10-auth_gssapi.conf /etc/httpd/conf.d/10-auth_gssapi.conf && \
    ln -s /etc/httpd/conf.modules.d/55-lookup_identity.conf /etc/httpd/conf.d/55-lookup_identity.conf && \
    mkdir -p /etc/httpd/saml2/ecp && \
    mkdir -p /etc/httpd/saml2/websso && \
    chown -R keystone:keystone /var/log/keystone
