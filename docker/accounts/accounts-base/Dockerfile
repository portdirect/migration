FROM fedora:22
LABEL License="Apache 2.0" \
      Vendor="Harbor OpenStack"
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO="HarborOS" \
    container=docker \
    SECURE_CONFIG="True" \
    OPENSTACK_COMPONENT="os-accounts" \
    OPENSTACK_SUBCOMPONENT="portal" \
    IPA_BACKED="True"

RUN curl -L https://copr.fedoraproject.org/coprs/mkosek/freeipa-4.2/repo/fedora-22/mkosek-freeipa-4.2-fedora-22.repo > \
      /etc/yum.repos.d/mkosek-freeipa-4.2-fedora-22.repo && \
    dnf update -y && \
    dnf install -y \
        findutils \
        freeipa-client \
        freeipa-admintools \
        perl 'perl(Data::Dumper)' 'perl(Time::HiRes)' \
        hostname \
        httpd \
        mod_ssl \
        mod_wsgi \
        python-memcached \
        python-pillow \
        git \
        python-cherrypy \
        python-jinja2 \
        python-sqlalchemy \
        python-pip \
        crudini && \
    dnf clean all && \
    pip install --upgrade pip && \
    pip install captcha>=0.2

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    chmod -v +x /usr/bin/systemctl /usr/sbin/ipa-client-install /init-ipa.sh /init && \
    ln -sf /etc/systemd/system/dbus.service /etc/systemd/system/messagebus.service && \
    git clone --depth 1 https://github.com/patternfly/patternfly.git /opt/patternfly && \
    mv /opt/patternfly/dist/ /opt/portal/freeipa_community_portal/assets && \
    cp -rf /opt/portal/freeipa_community_portal/custom/* /opt/portal/freeipa_community_portal/assets/ && \
    ls -lahR /opt/portal/freeipa_community_portal/assets && \
    pip install /opt/portal && \
    /usr/bin/freeipa-portal-install && \
    /bin/rm -rf /etc/httpd/conf.d/*.conf

CMD ["/init"]
