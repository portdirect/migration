#!/bin/sh
set -e
exec su -s /bin/sh -c "exec memcached -p 11211 -U 11211 -l 0.0.0.0" memcached
