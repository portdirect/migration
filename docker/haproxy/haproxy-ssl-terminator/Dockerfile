FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%haproxy-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT ssl-terminator

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* /

CMD ["/start.sh"]
