FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%centos:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="mysql"

ADD ./assets/etc/yum.repos.d/sclo7-rh-mysql56-rh-release.repo /etc/yum.repos.d/sclo7-rh-mysql56-rh-release.repo
RUN curl https://trunk.rdoproject.org/centos7-mitaka/delorean-deps.repo > /etc/yum.repos.d/delorean-deps.repo && \
    curl https://trunk.rdoproject.org/centos7-mitaka/current/delorean.repo > /etc/yum.repos.d/delorean-current.repo && \
    yum update -y && \
    yum install -y \
        rh-mysql56 \
        rh-mysql56-mysql-server \
        rh-mysql56-mysql  \
        openstack-trove-guestagent \
        percona-xtrabackup \
        python-pip \
        mariadb && \
    yum clean all

VOLUME [ "/var/lib/mysql/data" , "/var/tmp"]

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    mv /usr/lib/systemd/system/rh-mysql56-mysqld.service /usr/lib/systemd/system/mysqld.service && \
    chown -R mysql:mysql /etc/my.cnf && \
    mkdir -p /etc/mysql/conf.d/ && \
    chown -R mysql:mysql /etc/mysql/conf.d && \
    mkdir -p /var/lib/mysql/data && \
    chown -R mysql:mysql /var/lib/mysql/data && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    echo "trove ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chmod 0440 /etc/sudoers
