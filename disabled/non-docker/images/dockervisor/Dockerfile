FROM centos:7
MAINTAINER "Pete Birley" <petebirley@gmail.com>

ENV container docker
RUN yum -y install \
        systemd-container \
        systemd-container-libs && \
    yum -y update && \
    yum clean all && \
    (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]


ADD virt7-testing.repo /etc/yum.repos.d/virt7-testing.repo

RUN yum -y install \
        docker \
        kubernetes \
        etcd \
        ca-certificates && \
    yum clean all


RUN rm -rf /usr/bin/docker && \
    curl -L https://get.docker.com/builds/Linux/x86_64/docker-latest > /usr/bin/docker && \
    chmod +x /usr/bin/docker

ADD dockervisor.service /usr/lib/systemd/system/dockervisor.service

RUN ln -s '/usr/lib/systemd/system/dockervisor.service' '/etc/systemd/system/multi-user.target.wants/dockervisor.service'

CMD ["/usr/sbin/init"]










docker build -t "cannyos/dockervisor" .


cockpit-kubernetes