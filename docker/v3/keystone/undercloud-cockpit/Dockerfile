FROM centos:latest
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO="HarborOS" \
    container=docker \
    OPENSTACK_COMPONENT="os-cockpit"

ADD /assets/etc/yum.repos.d/cockpit-preview.repo /etc/yum.repos.d/cockpit-preview.repo
RUN yum -y install \
        findutils \
        systemd \
        openssh-server \
        openssh-clients \
        sssd-dbus \
        cockpit-ws \
        cockpit-bridge \
        cockpit-docker \
        cockpit-kubernetes && \
    yum clean all

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    find /etc/systemd/system/* '!' -name '*.wants' | xargs rm -rvf && \
    for i in basic.target sysinit.target network.service netconsole.service ; do \
        rm -f /usr/lib/systemd/system/$i && \
        ln -s /dev/null /usr/lib/systemd/system/$i ;\
    done && \
    /sbin/ldconfig -X && \
    rmdir -v /etc/systemd/system/multi-user.target.wants && \
    mkdir /etc/systemd/system/container-up.target.wants && \
    ln -s /etc/systemd/system/container-up.target.wants /etc/systemd/system/multi-user.target.wants && \
    systemctl set-default container-up.target && \
    systemctl enable container-configure-first.service && \
    ln -s /usr/lib/systemd/system/dummy-service.service /usr/lib/systemd/system/rhel-domainname.service

CMD ["/usr/sbin/init"]
