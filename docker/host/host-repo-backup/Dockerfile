FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%host-base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN yum install -y \
        httpd && \
    yum clean all

VOLUME /tmp

ADD ./assets /assets

RUN ostree --repo=/srv/repo init --mode=archive-z2



RUN cd tmp && \
    rpm-ostree compose --repo=/srv/repo tree /assets/harbor-host.json

#RUN cd tmp && \
#    rpm-ostree compose --repo=/srv/repo tree /assets/harbor-guest.json

RUN ostree refs --repo /srv/repo/


ADD ./start.sh /start.sh

RUN ln -s /srv/repo/ /var/www/html/repo && \
    rm -f /etc/httpd/conf.d/welcome.conf && \
    chmod +x /start.sh

CMD ["/start.sh"]
