#!/bin/bash

# Copyright 2015 Nathan Kinder
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

set -e

function stop_running () {
	systemctl stop-running
}
trap stop_running TERM

# Call the freeipa-client entrypoint script
/usr/sbin/ipa-client-configure-first -s $@

# Check if Ipsilon has already been installed
if [ ! -e /etc/ipsilon-installed ] ; then
    # Determine the Kerberos realm name
    DOMAIN=$(dnsdomainname)
    REALM=${DOMAIN^^}

    # Obtain a Kerberos ticket to perform IPA admin operations
    echo "$PASSWORD" | kinit admin

    # Update our A record if requested
    if [ $IPSILON_IP_ADDRESS ] ; then
        ipa dnsrecord-mod $(dnsdomainname) $(hostname -s) --a-rec=$IPSILON_IP_ADDRESS
    fi

    # Add a service for Ipsilon in FreeIPA
    ipa service-add HTTP/$(hostname -f)@$REALM

    # Enable certmonger and get a certificate for TLS
    systemctl enable certmonger.service
    systemctl start certmonger.service
    ipa-getcert request -w -k /etc/pki/tls/private/ipsilon.key -f /etc/pki/tls/certs/ipsilon.crt

    # Configure mod_ssl to use our certificate
    sed -i 's/localhost\.crt/ipsilon\.crt/' /etc/httpd/conf.d/ssl.conf
    sed -i 's/localhost\.key/ipsilon\.key/' /etc/httpd/conf.d/ssl.conf

    # Allow the default Ipsilon installer options to be overridden
    if [ -z $IPSILON_INSTALL_OPTIONS ] ; then
        IPSILON_INSTALL_OPTIONS="--ipa yes --krb yes --saml2 yes --admin-user admin"
    fi

    # Install Ipsilon
    if /usr/sbin/ipsilon-server-install $IPSILON_INSTALL_OPTIONS ; then
        # Enable local mapping to allow Kerberos or form-based admin access
        sed -i 's/# KrbLocalUserMapping On/KrbLocalUserMapping On/' /etc/httpd/conf.d/ipsilon-idp.conf

        # Set up a redirect rule for httpd
        echo "RedirectMatch ^/\$ https://$(hostname -f)/idp" >> /etc/httpd/conf.d/ipsilon-idp.conf

        echo 'Ipsilon server configured.'
        touch /etc/ipsilon-installed
        systemctl enable httpd.service

        # Destroy our Kerberos credentials cache
        kdestroy
    else
        ret=$?
        echo 'Ipsilon server configuration failed.'
        exit $ret
    fi
fi

# Start Ipsilon
echo 'Starting Certmonger'
systemctl start certmonger.service
echo 'Starting Ipsilon'
systemctl start httpd.service
echo 'Ipsilon started'

# Start a shell if requested, otherwise loop forever
if [ -t 0 ] ; then
    echo 'Starting interactive shell.'
    /bin/bash
else
    echo 'Go loop.'
    while true ; do sleep 1000 & wait $! ; done
fi
