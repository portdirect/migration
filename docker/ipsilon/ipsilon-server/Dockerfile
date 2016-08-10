FROM %%DOCKER_NAMESPACE%%/%%DOCKER_PREFIX%%ipsilon-base:%%DOCKER_TAG%%
ENV OPENSTACK_SUBCOMPONENT="server" \
    IPA_BACKED="True"

RUN yum install -y \
      python-psycopg2 && \
    yum clean all

RUN curl -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/css/patternfly.css > /usr/share/ipsilon/ui/css/patternfly.css && \
    curl -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/css/patternfly-additions.css > /usr/share/ipsilon/ui/css/patternfly-additions.css && \
    curl -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Regular-webfont.woff > /usr/share/ipsilon/ui/fonts/OpenSans-Regular-webfont.woff && \
    curl -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Semibold-webfont.woff > /usr/share/ipsilon/ui/fonts/OpenSans-Semibold-webfont.woff && \
    curl -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Regular-webfont.ttf > /usr/share/ipsilon/ui/fonts/OpenSans-Regular-webfont.ttf && \
    curl -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Semibold-webfont.ttf > /usr/share/ipsilon/ui/fonts/OpenSans-Semibold-webfont.ttf && \
    curl -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/img/bg-navbar-pf-alt.svg > /usr/share/ipsilon/ui/img/bg-navbar-pf-alt.svg



ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    systemctl enable dbus
