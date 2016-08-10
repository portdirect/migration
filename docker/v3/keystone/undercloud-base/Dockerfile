FROM alpine:latest

ENV OS_DISTRO="HarborDev"

ADD ./assets /opt/harbor/assets

RUN apk add --no-cache --virtual core-deps \
      python \
      sudo \
      curl && \
    chmod 0640 /etc/sudoers && \
    sed -i '/Defaults    requiretty/s/^/#/' /etc/sudoers && \
    chmod 0440 /etc/sudoers && \
    python -m ensurepip && \
    pip --no-cache-dir install --upgrade pip setuptools && \
    pip install crudini && \
    pip install PyMySQL===0.7.5 && \
    pip install python-memcached && \
    cp -rf /opt/harbor/assets/* / && \
    rm -rf /opt/harbor/assets

CMD ["/start.sh"]
