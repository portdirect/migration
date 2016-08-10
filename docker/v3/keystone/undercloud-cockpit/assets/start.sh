#!/bin/bash
set -e
ROOT_PASSWORD="password"
echo "root:${ROOT_PASSWORD}" | chpasswd

# Link docker socket from host to required location.
# We cant just put in in the right place as systemd creates a tmpfs for /run
ln -s /host/docker.sock /var/run/docker.sock

systemctl start cockpit
systemctl enable cockpit.socket
