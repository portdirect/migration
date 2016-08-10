FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%foreman-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="puppet-master"

RUN yum -y install \
        puppet-server \
        httpd \
        mod_ssl \
        rubygem-rack \
        mod_passenger \
        foreman-proxy && \
   yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    mkdir -p /usr/share/puppet/rack/puppetmasterd/public && \
    mkdir -p /usr/share/puppet/rack/puppetmasterd/tmp && \
    cp /usr/share/puppet/ext/rack/config.ru /usr/share/puppet/rack/puppetmasterd/ && \
    chown -R puppet.puppet /usr/share/puppet/rack && \
    mkdir -p /var/run/passenger && \
    systemctl mask ipmievd.service && \
    chown puppet:puppet /etc/puppet/node.rb && \
    chmod +x /etc/puppet/node.rb
