#!/bin/bash
set -e
# Copyright 2014--2015 Jan Pazdziora
# Copyright 2015--2015 Pete Birley
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi

: ${OS_DOMAIN:="kube.local"}

################################################################################
echo "${OS_DISTRO}: IPA: Configuring hosts file"
################################################################################
ETH0_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)
cat > /etc/hosts <<EOF
# HArbor-managed hosts file.
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
fe00::0 ip6-mcastprefix
fe00::1 ip6-allnodes
fe00::2 ip6-allrouters
${ETH0_IP} $(hostname -s).${OS_DOMAIN} $(hostname -s)
EOF


function usage () {
	if [ -n "$1" ] ; then
		echo $1 >&2
	else
		echo "Start as docker run -e IPA_HOST_ADMIN_USER=x -e $IPA_HOST_ADMIN_PASSWORD=y" >&2
		echo "    with -h <the-FQDN-hostname> and possibly --link <FreeIPA-container>:ipa" >&2
	fi
	exit 1
}

function stop_running () {
	systemctl stop-running
}
trap stop_running TERM

systemctl stop dbus.service
rm -rf /var/run/*.pid
rm -f /run/systemctl-lite-running/*


if [ -f /etc/ipa/ca.crt ] ; then
	HOSTNAME_IPA=$(cat /etc/hostname.ipa-client)
	if [ ! "$HOSTNAME_IPA" == "$(hostname -f)" ] ; then
		if hostname $HOSTNAME_IPA ; then
			################################################################################
			echo "${OS_DISTRO}: IPA: Hostname: $HOSTNAME_IPA"
			################################################################################
		else
			################################################################################
			echo "${OS_DISTRO}: IPA: The container hostname is $(hostname -f) and cannot set $HOSTNAME_IPA; run with -h."
			################################################################################
			exit 1
		fi
	fi
	################################################################################
	echo "${OS_DISTRO}: IPA: System is enrolled, starting services."
	################################################################################
	systemctl start-enabled
	################################################################################
	echo "${OS_DISTRO}: IPA: Services Ready"
	################################################################################
else
	if [ -z "$IPA_HOST_ADMIN_USER" ] ; then
		usage
	fi
	if [ -z "$IPA_HOST_ADMIN_PASSWORD" ] ; then
		usage
	fi
	HOSTNAME_OPTS=--hostname=$OS_HOSTNAME
	################################################################################
	echo "${OS_DISTRO}: IPA: Installing client"
	################################################################################
	/usr/sbin/ipa-client-install "$IPA_CLIENT_INSTALL_OPTS" "$HOSTNAME_OPTS" -p "$IPA_HOST_ADMIN_USER" -w "$IPA_HOST_ADMIN_PASSWORD" -U --enable-dns-updates --no-ntp --force-join < /dev/null
	cp -f /etc/hostname /etc/hostname.ipa-client

	################################################################################
	echo "${OS_DISTRO}: IPA: Enrolled!"
	################################################################################
fi

################################################################################
echo "${OS_DISTRO}: INIT: Running start script"
################################################################################
exec /start.sh
