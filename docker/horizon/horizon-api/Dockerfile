FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%horizon-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="api" \
    INIT_DB_REQUIRED="False"

RUN rm -f /opt/patternfly-sass/assets/images/patternfly/bg-login.jpg
ADD ./assets /opt/harbor/assets

RUN rm -rf /usr/lib/python2.7/site-packages/muranodashboard/environments/tabs.py* && \
    /bin/cp -rf /opt/harbor/assets/* / && \
    rm -f /opt/horizon/openstack_dashboard/enabled/*.pyc && \
    rm -f /opt/horizon/openstack_dashboard/enabled/_9001_developer.py* && \
    rm -f /opt/horizon/openstack_dashboard/enabled/_1710_project_dns_panel_group.py* && \
    sed -i "s/PANEL_GROUP = 'dns'/PANEL_GROUP = 'network'/" /opt/horizon/openstack_dashboard/enabled/_1720_project_dns_panel.py && \
    /opt/horizon/manage.py collectstatic --noinput && \
    /opt/horizon/manage.py compress
