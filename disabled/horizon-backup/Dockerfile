FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OPENSTACK_COMPONENT os-horizon
ENV OPENSTACK_SUBCOMPONENT api
ENV INIT_DB_REQUIRED True
EXPOSE 80/tcp

RUN yum install -y \
        openstack-dashboard \
        httpd \
        httpd-tools \
        mod_wsgi \
        mod_ssl \
        web-assets-filesystem \
        python-memcached \
        python-ceilometerclient \
        python-saharaclient \
        python-swiftclient \
        python-troveclient \
        python-pip && \
    yum clean all && \
    pip install --upgrade pip

RUN yum install -y git gcc python-devel
RUN git clone --depth 1 https://github.com/openstack/horizon.git /opt/horizon && \
    git clone --depth 1 https://github.com/openstack/murano-dashboard.git /opt/murano-dashboard && \
    git clone --depth 1 https://github.com/openstack/app-catalog-ui.git /opt/app-catalog-ui && \
    git clone --depth 1 https://github.com/openstack/magnum-ui.git /opt/magnum-ui

ADD assets/harbor-theme/static/images/harbor/favicon.ico /opt/horizon

RUN pip install /opt/horizon && \
    useradd --user-group horizon && \
    mkdir -p /etc/openstack-dashboard /home/horizon && \
    ln -s /etc/openstack-dashboard/local_settings /opt/horizon/openstack_dashboard/local/local_settings.py

RUN pip install /opt/murano-dashboard && \
    cp /opt/murano-dashboard/muranodashboard/local/_50_murano.py /opt/horizon/openstack_dashboard/enabled/ && \
    pip install /opt/app-catalog-ui && \
    cp -a /opt/app-catalog-ui/app_catalog/enabled/* /opt/horizon/openstack_dashboard/enabled/ && \
    pip install /opt/magnum-ui && \
    cp /opt/magnum-ui/enabled/*.py /opt/horizon/openstack_dashboard/enabled/

RUN pip install --upgrade six
RUN pip install --upgrade XStatic-Magic-Search
ADD assets/harbor-theme /opt/horizon/openstack_dashboard/themes/harbor

RUN sed -i "s,#CUSTOM_THEME_PATH = 'themes/default',CUSTOM_THEME_PATH = 'themes/harbor',g" /etc/openstack-dashboard/local_settings
RUN echo "COMPRESS_OFFLINE = True" >> /etc/openstack-dashboard/local_settings && \
    /opt/horizon/manage.py collectstatic --noinput && \
    /opt/horizon/manage.py compress && \
    /opt/horizon/manage.py  make_web_conf --wsgi && \
    mkdir -p /etc/httpd/conf.d.disabled && \
    mv /etc/httpd/conf.d/* /etc/httpd/conf.d.disabled/ && \
    mv /etc/httpd/conf.d.disabled/ssl.conf /etc/httpd/conf.d/ssl.conf && \
    /opt/horizon/manage.py make_web_conf --apache > /etc/httpd/conf.d/horizon.conf

ADD ./start.sh /start.sh
