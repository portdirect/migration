#!/bin/sh

mkdir -p /etc/kuryr
cat > /etc/kuryr/kuryr.conf << EOF
[DEFAULT]

bindir = /usr/libexec/kuryr
capability_scope = $CAPABILITY_SCOPE
EOF

cd /opt/kuryr-libnetwork
exec /usr/sbin/uwsgi \
    --plugin /usr/lib/uwsgi/python \
    --http-socket :23750 \
    -w kuryr_libnetwork.server:app \
    --master \
    --processes "$PROCESSES" \
    --threads "$THREADS"
