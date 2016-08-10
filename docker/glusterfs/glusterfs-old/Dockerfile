FROM centos:7
LABEL License="Apache 2.0" \
      Vendor="Harbor OpenStack"
MAINTAINER Pete Birley <petebirley@gmail.com>

ENV GLUSTER_VERSION="3.7" \
    container="docker"

RUN yum --setopt=tsflags=nodocs -y install \
        centos-release-gluster37 && \
    yum update -y && \
    (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
        rm -f /lib/systemd/system/multi-user.target.wants/*;\
        rm -f /etc/systemd/system/*.wants/*;\
        rm -f /lib/systemd/system/local-fs.target.wants/*; \
        rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
        rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
        rm -f /lib/systemd/system/basic.target.wants/*;\
        rm -f /lib/systemd/system/anaconda.target.wants/* && \
    yum --setopt=tsflags=nodocs -y install \
        xfsprogs \
        glusterfs-server \
        glusterfs-geo-replication \
        glusterfs-extra-xlators \
        glusterfs-coreutils \
        glusterfs-ganesha \
        etcd \
        bind-utils && \
    yum clean all

# gluster ports: daemon, infiniband, brick 1-100
EXPOSE 24007 24008 49152-49251

# nfs ports and portmapper
EXPOSE 2049 38465-38467 111/udp 111

CMD ["/sbin/init"]

ADD update-etcd.sh /bin/
RUN chmod +x /bin/update-etcd.sh
ADD gluster-etcd.service /etc/systemd/system/

ADD bootstrap-gluster.sh /bin/
RUN chmod +x /bin/bootstrap-gluster.sh
ADD gluster-bootstrap.service /etc/systemd/system/

RUN systemctl enable \
      glusterd \
      glusterfsd \
      gluster-etcd \
      gluster-bootstrap \
      nfs-ganesha

ADD glusterd.vol /etc/glusterfs/glusterd.vol
