FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%haproxy-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT frontend

RUN apk update && \
    apk upgrade && \
    apk add --update \
        inotify-tools \
        socat \
        curl && \
    rm -Rf var/cache/apk/* && \
    mkdir -p /var/state/haproxy

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /

RUN for ERROR in 400 403 404 408 500 502 503 504; do \
    echo "" >> /usr/share/haproxy/errors/${ERROR}.http; \
    curl https://raw.githubusercontent.com/portdirect/server-error-pages/gh-pages/_site/${ERROR}-error.html >> /usr/share/haproxy/errors/${ERROR}.http; \
    done



CMD ["/start.sh"]
