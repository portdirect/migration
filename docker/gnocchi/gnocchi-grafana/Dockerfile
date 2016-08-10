FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
ENV OPENSTACK_COMPONENT="gnocchi" \
    OPENSTACK_SUBCOMPONENT="grafana"

RUN yum install -y \
        git \
        https://grafanarel.s3.amazonaws.com/builds/grafana-2.6.0-1.x86_64.rpm && \
    yum clean all && \
    git clone --depth 1 http://github.com/sileht/grafana-plugins-gnocchi.git /opt/grafana-plugins-gnocchi && \
    mv /opt/grafana-plugins-gnocchi/datasources/gnocchi /usr/share/grafana/public/app/plugins/datasource/

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /
