#!/bin/bash
(
DOCKER_NAMESPACE=port
DOCKER_TAG=latest

DOCKER_CMD=docker
docker pull ${DOCKER_NAMESPACE}/host-repo:${DOCKER_TAG}

REPO_IMAGE=$(docker run -d ${DOCKER_NAMESPACE}/host-repo:${DOCKER_TAG})
rm -rf /srv/*
docker cp ${REPO_IMAGE}:/srv/repo /srv/
docker cp ${REPO_IMAGE}:/assets/ /tmp/atomic/

docker stop ${REPO_IMAGE}
docker rm ${REPO_IMAGE}

rpm-ostree-toolbox installer --ostreerepo /srv/repo -c /tmp/atomic/config.ini -o /srv/installer
rm -rf /srv/repo

cat > /srv/Dockerfile <<EOF
FROM centos:7
RUN yum update -y && \
    yum install -y \
        httpd && \
    yum clean all
ADD ./installer /srv/installer
RUN ln -s /srv/installer/ /var/www/html/installer && \
    rm -f /etc/httpd/conf.d/welcome.conf

CMD /usr/sbin/httpd -DFOREGROUND
EOF
rm -rf /srv/installer
docker build -t ${DOCKER_NAMESPACE}/host-installer:${DOCKER_TAG} /srv/
docker push ${DOCKER_NAMESPACE}/host-installer:${DOCKER_TAG}
)
