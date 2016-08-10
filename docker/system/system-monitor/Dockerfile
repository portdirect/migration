FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%system-base:%%DOCKER_TAG%%

RUN apk update && \
    apk upgrade && \
    apk add --update \
        iftop \
        nload
