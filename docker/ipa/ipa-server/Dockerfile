FROM port/docker-freeipa-centos-7-upstream:latest
MAINTAINER Pete Birley <petebirley@gmail.com>

ADD ./assets /opt/harbor/assets
RUN /bin/cp -rf /opt/harbor/assets/* / && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/css/patternfly.css > /usr/share/ipa/ui/css/patternfly.css && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/css/patternfly-additions.css > /usr/share/ipa/ui/css/patternfly-additions.css && \
    mkdir -p /usr/share/ipa/ui/img && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/img/bg-navbar-pf-alt.svg > /usr/share/ipa/ui/img/bg-navbar-pf-alt.svg && \
    mkdir -p /usr/share/ipa/ui/fonts && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Bold-webfont.woff > /usr/share/ipa/ui/fonts/OpenSans-Bold-webfont.woff && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Regular-webfont.woff > /usr/share/ipa/ui/fonts/OpenSans-Regular-webfont.woff && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Semibold-webfont.woff > /usr/share/ipa/ui/fonts/OpenSans-Semibold-webfont.woff && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Light-webfont.woff > /usr/share/ipa/ui/fonts/OpenSans-Light-webfont.woff && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Bold-webfont.ttf > /usr/share/ipa/ui/fonts/OpenSans-Bold-webfont.ttf && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Light-webfont.ttf > /usr/share/ipa/ui/fonts/OpenSans-Light-webfont.ttf && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Regular-webfont.ttf > /usr/share/ipa/ui/fonts/OpenSans-Regular-webfont.ttf && \
    curl --insecure -L https://raw.githubusercontent.com/patternfly/patternfly/master/dist/fonts/OpenSans-Semibold-webfont.ttf > /usr/share/ipa/ui/fonts/OpenSans-Semibold-webfont.ttf && \
    curl --insecure -L https://github.com/FortAwesome/Font-Awesome/raw/master/fonts/fontawesome-webfont.ttf > /usr/share/ipa/ui/fonts/fontawesome-webfont.ttf && \
    curl --insecure -L https://github.com/FortAwesome/Font-Awesome/raw/master/fonts/fontawesome-webfont.woff > /usr/share/ipa/ui/fonts/fontawesome-webfont.woff && \
    curl --insecure -L https://github.com/FortAwesome/Font-Awesome/raw/master/fonts/fontawesome-webfont.woff2 > /usr/share/ipa/ui/fonts/fontawesome-webfont.woff2
