FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%

RUN apk update && \
    apk add --update \
        bridge-utils \
        sipcalc \
        drill \
        curl && \
    rm /var/cache/apk/*

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    chmod +x /bin/* && \
    chmod +x /opt/harbor/assets/host/bin/*
