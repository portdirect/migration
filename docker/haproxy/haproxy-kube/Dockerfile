FROM docker.io/alpine:latest

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /

ADD service_loadbalancer service_loadbalancer
ADD service_loadbalancer.go service_loadbalancer.go
