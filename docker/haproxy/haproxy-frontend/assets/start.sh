#!/bin/sh
set -e
################################################################################
echo "${OS_DISTRO}: Generating local environment file from secrets_dir"
################################################################################
SECRETS_DIR=/etc/os-config
find $SECRETS_DIR -type f -print -exec sh -c "cat {} | sed  's|\\\n$||g'" \; > /etc/os-container.env
sed -i '/^\// d' /etc/os-container.env


################################################################################
echo "${OS_DISTRO}: Sourcing local environment variables"
################################################################################
source /etc/os-container.env

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Launching haproxy"
################################################################################

# 1st launch with a default config that just listens on localhost anddiaplays the stats page
# This means that we can reload fron a known good state:
# Preventing haproxy loading a bad config initially, that it cannot recover from
mkdir -p /var/state/haproxy
(echo "show servers state" | socat /tmp/haproxy - ) > /var/state/haproxy/global
cp -f /usr/lib/haproxy/haproxy.cfg /tmp/haproxy.cfg
haproxy -f /tmp/haproxy.cfg -p /var/run/haproxy.pid -D

################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Waiting For inital update"
################################################################################
until [ -f /etc/haproxy/haproxy.cfg ] ; do
     sleep 5
     echo "still waiting"
done

# Watch for config file updates and reload haproxy
while ( inotifywait -t 10 -e close_write /etc/haproxy/haproxy.cfg || true ) ; do
  cp -f /etc/haproxy/haproxy.cfg /tmp/haproxy-working.cfg || true
  CHKSUM_EXISTING=$(md5sum /tmp/haproxy.cfg | awk '{print $1}')
  CHKSUM_NEW=$(md5sum /tmp/haproxy-working.cfg | awk '{print $1}')
  if [ "$CHKSUM_EXISTING" != "$CHKSUM_NEW" ]; then
    cp -f /tmp/haproxy-working.cfg /tmp/haproxy.cfg
    (haproxy -c -f /tmp/haproxy.cfg && (
    (echo "show servers state" | socat /tmp/haproxy - ) > /var/state/haproxy/global
    haproxy -f /tmp/haproxy.cfg -p /var/run/haproxy.pid -D -sf $(cat /var/run/haproxy.pid)
    )) || echo "Config File Verificaion Failed: not loading"
  fi
done
