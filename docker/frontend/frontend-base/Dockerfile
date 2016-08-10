FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%base:%%DOCKER_TAG%%
MAINTAINER Pete Birley <petebirley@gmail.com>

RUN yum install -y \
        git \
        nginx \
        nodejs \
        npm \
        ruby \
        ruby-devel \
        rubygems \
        make \
    && yum clean all

RUN gem install jekyll

ADD ./start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/init"]
