#!/bin/sh
set -e
# Launch Gluster daemon
exec /usr/sbin/glusterd --no-daemon --log-level=DEBUG --log-file=/dev/stdout
