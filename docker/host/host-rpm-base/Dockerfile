FROM centos:7
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN yum update -y && \
    yum groupinstall -y \
        "Development Tools" && \
    yum install -y \
        openssl-devel \
        ncurses-devel \
        ncurses \
        bc \
        rpmdevtools \
        ruby-devel \
        gcc \
        make \
        git \
        rpm-build \
        httpd \
        createrepo && \
  gem install fpm && \
  mkdir -p /srv/repo/atomic-host/7/{SRPMS,i386,x86_64,noarch} && \
  chmod -R 0777 /srv/repo/atomic-host/7/{SRPMS,i386,x86_64,noarch} && \
  useradd user
