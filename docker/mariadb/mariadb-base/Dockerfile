FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%

#ADD MariaDB.repo /etc/yum.repos.d/
RUN yum -y install \
        mariadb-server \
        mariadb-client \
        MySQL-python \
        hostname && \
    yum clean all
