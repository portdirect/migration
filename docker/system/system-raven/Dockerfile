FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%

ENV RAVEN_REPO="https://github.com/midonet/kuryr.git" \
    RAVEN_BRANCH="k8s"

WORKDIR /

RUN apk add --no-cache \
      python3 && \
    apk add --no-cache --virtual build-deps \
        gcc \
        git \
        linux-headers \
        musl-dev \
        python3-dev && \
    python3 -m ensurepip && \
    pip3 --no-cache-dir install --upgrade pip setuptools

ADD ./assets/kuryr /opt/kuryr

RUN pip3 install /opt/kuryr && \
    mkdir -p /etc/raven && \
    cp /opt/kuryr/etc/raven.conf.sample /etc/raven/raven.conf && \
    apk del build-deps && \
    mkdir -p /var/log/raven && \
    addgroup kuryr -g 1000 && \
    adduser -u 1000 -D -s /bin/false -G kuryr kuryr

#Run as root during dev
#USER kuryr

CMD ["/usr/bin/raven","--config-file","/etc/raven/raven.conf"]
