FROM centos:7
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO="HarborOS" \
    IPA_BACKED="True" \
    container=docker \
    OPENSTACK_COMPONENT="os-foreman"

ADD ./assets/etc/yum.repos.d /opt/harbor/assets/etc/yum.repos.d
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    curl -L https://copr.fedorainfracloud.org/coprs/g/freeipa/freeipa-4-3-centos-7/repo/epel-7/pvoborni-freeipa-4-3-centos-7-epel-7.repo > /etc/yum.repos.d/pvoborni-freeipa-4-3-centos-7-epel-7.repo && \
    yum -y install \
        http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm && \
    yum -y install \
        http://yum.theforeman.org/releases/latest/el7/x86_64/foreman-release.rpm && \
    yum -y install \
        epel-release && \
    yum update -y && \
    yum upgrade -y && \
    yum -y install \
        ipa-admintools \
        ipa-client \
        openssh-server \
        openssh-clients \
        httpd \
        mod_ssl \
        foreman-installer \
        crudini \
        etcd \
        puppet \
        sssd-dbus && \
    yum clean all


ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    find /etc/systemd/system/* '!' -name '*.wants' | xargs rm -rvf && \
    for i in basic.target sysinit.target network.service netconsole.service ; do \
        rm -f /usr/lib/systemd/system/$i && \
        ln -s /dev/null /usr/lib/systemd/system/$i ;\
    done && \
    localedef -c -i en_US -f UTF-8 en_US.UTF-8 && \
    /sbin/ldconfig -X && \
    rmdir -v /etc/systemd/system/multi-user.target.wants && \
    mkdir /etc/systemd/system/container-up.target.wants && \
    ln -s /etc/systemd/system/container-up.target.wants /etc/systemd/system/multi-user.target.wants && \
    systemctl set-default container-up.target && \
    systemctl enable container-configure-first.service && \
    chown puppet /etc/puppet/node.rb && \
    mv /etc/epel.repo /etc/yum.repos.d/epel.repo && \
    ln -s /usr/lib/systemd/system/dummy-service.service /usr/lib/systemd/system/rhel-domainname.service
