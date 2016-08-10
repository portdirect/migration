#!/bin/bash

DOCKER_NAMESPACE=docker.io/port
DOCKER_PREFIX=
DOCKER_TAG=latest

DOCKER_CMD=docker
${DOCKER_CMD} pull ${DOCKER_NAMESPACE}/host-repo:${DOCKER_TAG}

REPO_IMAGE=$(docker run -d ${DOCKER_NAMESPACE}/host-repo:latest)

${DOCKER_CMD} cp ${REPO_IMAGE}:/srv/repo /srv/
${DOCKER_CMD} cp ${REPO_IMAGE}:/assets/ /tmp/atomic/

${DOCKER_CMD} stop ${REPO_IMAGE}
${DOCKER_CMD} rm ${REPO_IMAGE}



iptables -I INPUT -s 192.168.124.0/24 -j ACCEPT
rm -rf /srv/images

rpm-ostree-toolbox imagefactory \
  --ostreerepo /srv/repo \
  --tdl /tmp/atomic/base.tdl \
  -c  /tmp/atomic/config.ini \
  -i vsphere \
  -i azure \
  -i kvm \
  -k /tmp/atomic/cloud.ks \
  -o /srv/images



gunzip harbor-host-7.qcow2.gz

rm -rf /srv/repo
(
cat > /srv/Dockerfile <<EOF
FROM centos:7
RUN yum update -y && \
    yum install -y \
        httpd && \
    yum clean all
ADD ./images /srv/images
RUN ln -s /srv/images/ /var/www/html/images && \
    rm -f /etc/httpd/conf.d/welcome.conf

CMD /usr/sbin/httpd -DFOREGROUND
EOF
rm -rf /srv/images
docker build -t ${DOCKER_NAMESPACE}/host-images:${DOCKER_TAG} /srv/
docker push ${DOCKER_NAMESPACE}/host-images:${DOCKER_TAG}
)
