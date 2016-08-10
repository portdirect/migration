FROM docker.io/centos:latest
MAINTAINER Pete Birley <petebirley@gmail.com>
ENV OS_DISTRO HarborOS

RUN yum install -y epel-release && \
    yum update -y && \
    yum upgrade -y && \
    yum install -y \
        python \
        curl \
        which && \
    yum clean all && \
    curl -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-116.0.0-linux-x86_64.tar.gz > /tmp/google-cloud-sdk.tar.gz && \
    mkdir -p /opt/google-cloud-sdk && \
    tar xf /tmp/google-cloud-sdk.tar.gz -C /opt/google-cloud-sdk --strip-components=1 && \
    rm -f /tmp/google-cloud-sdk.tar.gz && \
    /opt/google-cloud-sdk/install.sh --usage-reporting false --quiet
