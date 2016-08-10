FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%foreman-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="master" \
    IPA_BACKED="True"

RUN yum -y install \
        foreman-release-scl \
        foreman \
        foreman-cli \
        foreman-selinux \
        foreman-mysql2 \
        foreman-proxy \
        mod_passenger \
        mod_auth_kerb \
        mod_authnz_pam \
        mod_intercept_form_submit \
        mod_lookup_identity \
        tfm-rubygem-passenger \
        tfm-rubygem-passenger-native \
        tfm-rubygem-passenger-native-libs \
        passenger \
        mariadb \
        sssd-dbus && \
    yum clean all


RUN yum install -y \
        tfm-rubygem-foreman_docker \
        tfm-rubygem-foreman_discovery \
        tfm-rubygem-foreman-tasks \
        tfm-rubygem-foreman_setup \
        tfm-rubygem-foreman_bootdisk && \
    yum clean all

RUN yum install -y \
        yum-utils && \
    yumdownloader \
      --resolve \
      --destdir /opt/tfm-packages \
      tfm-rubygem-foreman_remote_execution && \
    yum clean all

RUN yum install -y \
        haproxy && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    systemctl mask ipmievd.service
