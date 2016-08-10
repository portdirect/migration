FROM gcr.io/google_containers/kube2sky:1.12
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS

ADD ./assets /opt/harbor/assets
RUN cp -rf /opt/harbor/assets/* /
ENTRYPOINT ["/start.sh"]
