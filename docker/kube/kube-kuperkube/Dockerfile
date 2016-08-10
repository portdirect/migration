FROM gcr.io/google_containers/hyperkube:v1.1.8
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/container/* / && \
    chmod +x /bin/* && \
    chmod +x /opt/harbor/assets/host/bin/*
