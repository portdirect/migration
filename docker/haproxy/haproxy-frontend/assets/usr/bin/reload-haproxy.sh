#!/bin/sh
set -e
(echo "show servers state" | socat /tmp/haproxy - ) > /var/state/haproxy/global
haproxy -f /etc/haproxy/haproxy-run.cfg -p /var/run/haproxy.pid -D -sf $(cat /var/run/haproxy.pid)
