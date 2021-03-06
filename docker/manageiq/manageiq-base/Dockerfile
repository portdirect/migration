FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-manageiq" \
    LANG="en_US.UTF-8" \
    TERM="xterm" \
    APP_ROOT="/var/www/miq/vmdb" \
    APPLIANCE_ROOT="/opt/manageiq/manageiq-appliance" \
    SSUI_ROOT="/opt/manageiq/manageiq-ui-self_service"

RUN curl -sSLko /etc/yum.repos.d/rhscl-rh-postgresql94-epel-7.repo \
    https://copr-fe.cloud.fedoraproject.org/coprs/rhscl/rh-postgresql94/repo/epel-7/rhscl-rh-postgresql94-epel-7.repo && \
    curl -sSLko /etc/yum.repos.d/ncarboni-pglogical-SCL-epel-7.repo \
    https://copr.fedorainfracloud.org/coprs/ncarboni/pglogical-SCL/repo/epel-7/ncarboni-pglogical-SCL-epel-7.repo && \
    yum -y install --setopt=tsflags=nodocs \
           bison \
           bzip2 \
           cmake \
           file \
           gcc-c++ \
           git \
           libffi-devel \
           libtool \
           libxml2-devel \
           libxslt-devel \
           libyaml-devel \
           make \
           memcached \
           net-tools \
           nodejs \
           openssl-devel \
           patch \
           rh-postgresql94-postgresql-server \
           rh-postgresql94-postgresql-devel \
           rh-postgresql94-postgresql-pglogical-output \
           rh-postgresql94-postgresql-pglogical \
           readline-devel \
           sqlite-devel \
           sysvinit-tools \
           which \
           httpd \
           mod_ssl \
           mod_auth_kerb \
           mod_authnz_pam \
           mod_intercept_form_submit \
           mod_lookup_identity \
           initscripts \
           npm \
           chrony \
           psmisc \
           lvm2 \
           openldap-clients \
           gdbm-devel&& \
    yum clean all


# Download chruby and chruby-install, install, setup environment, clean all
RUN curl -sL https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz | tar xz && \
    cd chruby-0.3.9 && \
        make install && \
        scripts/setup.sh && \
    echo "gem: --no-ri --no-rdoc --no-document" > ~/.gemrc && \
    echo "source /usr/local/share/chruby/chruby.sh" >> ~/.bashrc && \
    curl -sL https://github.com/postmodern/ruby-install/archive/v0.6.0.tar.gz | tar xz && \
    cd ruby-install-0.6.0 && \
        make install && \
        ruby-install ruby 2.2.4 -- --disable-install-doc && \
    echo "chruby ruby-2.2.4" >> ~/.bash_profile && \
    rm -rf /chruby-* && \
    rm -rf /usr/local/src/* && \
    yum clean all


## GIT clone manageiq-appliance and self-service UI repo (SSUI)
RUN git clone --depth 1 https://github.com/ManageIQ/manageiq-appliance.git ${APPLIANCE_ROOT} && \
    git clone --depth 1 https://github.com/ManageIQ/manageiq-ui-self_service.git ${SSUI_ROOT} && \
    ln -vs ${APP_ROOT} /opt/manageiq/manageiq && \
    git clone --depth 1 https://github.com/ManageIQ/manageiq.git ${APP_ROOT}

## Setup environment
RUN ${APPLIANCE_ROOT}/setup && \
    echo "export PATH=\$PATH:/opt/rubies/ruby-2.2.4/bin" >> /etc/default/evm && \
    mkdir ${APP_ROOT}/log/apache && \
    mv /etc/httpd/conf.d/ssl.conf{,.orig} && \
    echo "# This file intentionally left blank. ManageIQ maintains its own SSL configuration" > /etc/httpd/conf.d/ssl.conf && \
    echo "export APP_ROOT=${APP_ROOT}" >> /etc/default/evm

## Change workdir to application root, build/install gems
WORKDIR ${APP_ROOT}
RUN source /etc/default/evm && \
    /usr/bin/memcached -u memcached -p 11211 -m 64 -c 1024 -l 127.0.0.1 -d && \
    npm install npm -g && \
    npm install gulp bower -g && \
    gem install bundler -v ">=1.8.4" && \
    bin/setup --no-db --no-tests && \
    rake evm:compile_assets && \
    rake evm:compile_sti_loader && \
    rm -rvf /opt/rubies/ruby-2.2.4/lib/ruby/gems/2.2.0/cache/* && \
    bower cache clean && \
    npm cache clean

## Build SSUI
RUN source /etc/default/evm && \
    cd ${SSUI_ROOT} && \
    npm install && \
    bower -F --allow-root install && \
    gulp build && \
    bower cache clean && \
    npm cache clean


ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    echo "## Scripts symblinks" && \
    ln -s /var/www/miq/vmdb/docker-assets/docker_initdb /usr/bin && \
    echo "## Enable services on systemd" && \
    systemctl enable memcached && \
    systemctl enable appliance-initialize && \
    systemctl enable evmserverd && \
    systemctl enable evminit && \
    systemctl enable evm-watchdog && \
    systemctl enable miqvmstat && \
    systemctl enable miqtop

## Expose required container ports
EXPOSE 80 443

# Add persistent data volume for postgres
VOLUME [ "/var/opt/rh/rh-postgresql94/lib/pgsql/data" ]

## Call systemd to bring up system
CMD [ "/usr/sbin/init" ]
