FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%undercloud-base:%%DOCKER_TAG%%

ENV OS_COMP="mariadb"

ADD ./assets /opt/harbor/assets

RUN apk add --no-cache \
      mariadb \
      mariadb-client && \
      cp -rf /opt/harbor/assets/* / && \
      rm -rf /opt/harbor/assets
