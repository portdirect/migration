FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="os-horizon" \
    INIT_DB_REQUIRED="True"

RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum upgrade -y && \
    yum clean all

RUN yum install -y \
        openstack-dashboard \
        httpd \
        httpd-tools \
        mod_wsgi \
        mod_ssl \
        mod_auth_mellon \
        web-assets-filesystem \
        python-memcached \
        python-pip \
        git \
        gcc \
        python-devel \
        gettext && \
    git clone --depth 1 https://github.com/openstack/horizon.git /opt/horizon && \
      cd /opt/horizon && \
        pip install --upgrade pip && \
        pip install /opt/horizon  && \
        find . -type f | grep -i "\.git" | xargs rm && \
        useradd --user-group horizon && \
        mkdir -p /etc/openstack-dashboard /home/horizon && \
        ln -s /etc/openstack-dashboard/local_settings /opt/horizon/openstack_dashboard/local/local_settings.py && \
    git clone --depth 1 https://github.com/openstack/murano-dashboard.git /opt/murano-dashboard && \
        pip install /opt/murano-dashboard && \
        cp /opt/murano-dashboard/muranodashboard/local/_50_murano.py /opt/horizon/openstack_dashboard/enabled/ && \
    git clone --depth 1 https://github.com/openstack/app-catalog-ui.git /opt/app-catalog-ui && \
        pip install /opt/app-catalog-ui && \
        cp -a /opt/app-catalog-ui/app_catalog/enabled/* /opt/horizon/openstack_dashboard/enabled/ && \
    pip install --upgrade six && \
    pip install --upgrade XStatic-Magic-Search && \
    yum autoremove -y \
        gcc && \
    yum clean all && \
    mkdir -p /etc/httpd/conf.d.disabled && \
    mv /etc/httpd/conf.d/* /etc/httpd/conf.d.disabled/ && \
    mv /etc/httpd/conf.d.disabled/ssl.conf /etc/httpd/conf.d/ssl.conf

RUN echo "COMPRESS_OFFLINE = True" >> /etc/openstack-dashboard/local_settings && \
    /opt/horizon/manage.py collectstatic --noinput && \
    /opt/horizon/manage.py compress && \
    /opt/horizon/manage.py  make_web_conf --wsgi



RUN git clone --depth 1 https://github.com/openstack/cloudkitty-dashboard.git /opt/cloudkitty-dashboard && \
    pip install --upgrade /opt/cloudkitty-dashboard && \
    pip install python-cloudkittyclient && \
    cp -a /opt/cloudkitty-dashboard/cloudkittydashboard/enabled/_10_admin_group.py /opt/horizon/openstack_dashboard/enabled/ && \
    cp -a /opt/cloudkitty-dashboard/cloudkittydashboard/enabled/_10_project_group.py /opt/horizon/openstack_dashboard/enabled/ && \
    cp -a /opt/cloudkitty-dashboard/cloudkittydashboard/enabled/_11_admin_hashmap_panel.py /opt/horizon/openstack_dashboard/enabled/ && \
    cp -a /opt/cloudkitty-dashboard/cloudkittydashboard/enabled/_11_admin_rating_panel.py /opt/horizon/openstack_dashboard/enabled/ && \
    cp -a /opt/cloudkitty-dashboard/cloudkittydashboard/enabled/_11_project_rating_panel.py /opt/horizon/openstack_dashboard/enabled/ && \
    cp -a /opt/cloudkitty-dashboard/cloudkittydashboard/enabled/_12_project_reporting_panel.py /opt/horizon/openstack_dashboard/enabled/ && \
    cp -a /opt/cloudkitty-dashboard/cloudkittydashboard/enabled/_13_admin_pyscripts_panel.py /opt/horizon/openstack_dashboard/enabled/ && \
    /opt/horizon/manage.py collectstatic --noinput && \
    /opt/horizon/manage.py compress

RUN git clone --depth 1 https://github.com/openstack/magnum-ui.git /opt/magnum-ui && \
    pip install python-magnumclient && \
    pip install /opt/magnum-ui && \
    cp -a /opt/magnum-ui/magnum_ui/enabled/*.py /opt/horizon/openstack_dashboard/enabled/ && \
    /opt/horizon/manage.py collectstatic --noinput && \
    (cd /usr/lib/python2.7/site-packages/magnum_ui; DJANGO_SETTINGS_MODULE=openstack_dashboard.settings /opt/horizon/manage.py compilemessages) && \
    /opt/horizon/manage.py compress

RUN git clone --depth 1 https://github.com/openstack/trove-dashboard.git /opt/trove-dashboard && \
    pip install python-troveclient && \
    pip install /opt/trove-dashboard && \
    cp -a /opt/trove-dashboard/trove_dashboard/enabled/*.py /opt/horizon/openstack_dashboard/enabled/ && \
    /opt/horizon/manage.py collectstatic --noinput && \
    /opt/horizon/manage.py compress

RUN pip uninstall -y six && \
    easy_install six

RUN git clone --depth 1 https://github.com/openstack/manila-ui.git /opt/manila-ui && \
    pip install python-manilaclient && \
    pip install /opt/manila-ui && \
    cp -a /opt/manila-ui/manila_ui/enabled/*.py /opt/horizon/openstack_dashboard/enabled/ && \
    /opt/horizon/manage.py collectstatic --noinput && \
    /opt/horizon/manage.py compress

RUN git clone --depth 1 https://github.com/openstack/designate-dashboard.git /opt/designate-dashboard && \
    pip install python-designateclient && \
    pip install /opt/designate-dashboard && \
    cp -a /opt/designate-dashboard/designatedashboard/enabled/*.py /opt/horizon/openstack_dashboard/enabled/ && \
    /opt/horizon/manage.py collectstatic --noinput && \
    /opt/horizon/manage.py compress

RUN git clone --depth 1 https://github.com/patternfly/patternfly-sass.git /opt/patternfly-sass && \
    mkdir -p /opt/horizon/openstack_dashboard/themes/harbor/static && \
    ln -s /opt/patternfly-sass/assets /opt/horizon/openstack_dashboard/themes/harbor/static/

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    echo "AVAILABLE_THEMES = [" >> /etc/openstack-dashboard/local_settings && \
    echo "    ('harbor', 'Harbor', 'themes/harbor')," >> /etc/openstack-dashboard/local_settings && \
    echo "]" >> /etc/openstack-dashboard/local_settings && \
    /opt/horizon/manage.py collectstatic --noinput && \
    /opt/horizon/manage.py compress
