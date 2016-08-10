FROM centos:latest
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO="HarborOS" \
    IPA_BACKED="False" \
    SECURE_CONFIG="True" \
    container=docker
LABEL license="Apache 2.0" \
      vendor="Harbor OpenStack"

ADD ./assets/etc/yum.repos.d /opt/repos

#RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
#    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo
RUN /bin/cp -rf /opt/repos/* /etc/yum.repos.d/ && \
    rm -rf /opt/repos && \
    yum install -y \
        epel-release \
        centos-release-gluster37 \
        centos-release-openstack-mitaka && \
    yum update -y && \
    yum install -y \
        python-openstackclient \
        openstack-selinux \
        python-memcached \
        mariadb \
        MySQL-python \
        crudini \
        ipa-admintools \
        ipa-client \
        perl 'perl(Data::Dumper)' 'perl(Time::HiRes)' \
        dbus-python \
        etcd \
        kubernetes-client && \
    yum clean all

ADD ./assets/ /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /  && \
    ln -sf /etc/systemd/system/dbus.service /etc/systemd/system/messagebus.service && \
    ln -s /etc/systemd/system/dummy-service.service /etc/systemd/system/rhel-domainname.service && \
    mv /bin/systemctl /bin/systemctl-real && \
    mv /usr/local/bin/systemctl /bin/systemctl

CMD ["/init"]
