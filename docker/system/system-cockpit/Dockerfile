FROM centos:7
ENV OS_DISTRO HarborOS

ADD ./assets/container/etc/yum.repos.d/cockpit-preview.repo /etc/yum.repos.d/cockpit-preview.repo

RUN yum install -y \
        epel-release && \
    yum update -y && \
    yum upgrade -y && \
    yum install -y \
        cockpit-ws \
        cockpit-kubernetes \
        openssh-clients \
        openssh-server && \
    yum clean all && \
    mkdir -p /container && \
    ln -s /host/proc/1 /container/target-namespace && \
    rm -f /etc/os-release /usr/lib/os-release && \
    ln -sv /host/etc/os-release /etc/os-release && \
    ln -sv /host/usr/lib/os-release /usr/lib/os-release

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    chmod +x /container/init /container/install.sh

CMD ["/container/init", "--local-ssh"]
