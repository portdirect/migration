#!/bin/bash
#
# freeipa-pwd-portal container bootstrap. See the readme for details
#
################################################################################
echo "${OS_DISTRO}: ${OPENSTACK_COMPONENT}: ${OPENSTACK_SUBCOMPONENT}: Setting Up SSL"
################################################################################
HOST=$(cat /etc/os-ssl/host | sed 's/\\n/\n/g' | xargs)
mkdir -p /etc/pki/tls/private
cat /etc/os-ssl/key | sed 's/\\n/\n/g' > /etc/pki/tls/private/ca.key
mkdir -p /etc/pki/tls/certs
cat /etc/os-ssl/cirt | sed 's/\\n/\n/g' > /etc/pki/tls/certs/ca.crt
mkdir -p /etc/ipa
cat /etc/os-ssl/ca | sed 's/\\n/\n/g' | sed 's/\\r$//g' > /etc/ipa/ca.crt
mkdir -p /etc/pki
base64 --decode /etc/os-keytab/keytab > /etc/pki/host.keytab



openssl pkcs12 -export -in /etc/pki/tls/certs/ca.crt -inkey /etc/pki/tls/private/ca.key -chain -CAfile /etc/ipa/ca.crt -out /etc/pki/tls/private/ca.p12 -name "password.port.direct" -passout pass:password
echo "password" | keytool -importkeystore -srckeystore /etc/pki/tls/private/ca.p12 \
        -srcstoretype PKCS12 \
        -alias "password.port.direct" \
        -destkeystore /tmp/keystore.jks \
        -deststoretype JKS \
        -storepass "password"

SMTP_HOST="smtp.example.com"
SMTP_PORT="25"
SMTP_FROM="password@${OS_DOMAIN}"
FREEIPA_REALM="PORT.DIRECT"
FREEIPA_HOSTNAME="freeipa-master.${OS_DOMAIN}"
FREEIPA_PWD_PORTAL_PRINCIPAL="host/password.${OS_DOMAIN}@PORT.DIRECT"
FREEIPA_SSL_CERT="/etc/ipa/ca.crt"
KEYTAB="/etc/pki/host.keytab"

#
# Define some necessary global defaults
#
export FREEIPA_REALM=${FREEIPA_REALM:-EXAMPLE.COM}
export FREEIPA_REALM_LOWERCASE=${FREEIPA_REALM,,}
export FREEIPA_HOSTNAME=${FREEIPA_HOSTNAME:-freeipa.${OS_DOMAIN}}

export FREEIPA_PWD_PORTAL_KEYSTORE=${FREEIPA_PWD_PORTAL_KEYSTORE:-/etc/pki/tls/private/ca.p12}
export FREEIPA_PWD_PORTAL_KEY_PASS=${FREEIPA_PWD_PORTAL_KEY_PASS:-changeit}
export FREEIPA_PWD_PORTAL_KEY_ALIAS=${FREEIPA_PWD_PORTAL_KEY_ALIAS:-freeipa-pwd-portal}

JRE_KEYSTORE_PATH="/etc/ssl/certs/java/cacerts"
JRE_KEYSTORE_PASS="changeit"
DATA_PATH=/data

function create_config {
  if [[ -e "$2" && ! -f "$3" ]]; then
    echo "Generating a $1 config file and backing it up to $3"
    mkdir -p "$(dirname "$3")"
    eval "echo \"`cat "$2"`\"" > "$3"
    rm "$2"
  else
    echo "$1 template config file was already found; skipping"
  fi
}

#
# Generate the configuration file templates from the passed environment
# variables
#
create_config "Krb5" /default_krb5.conf /etc/iris-template/krb5.conf
create_config "JAAS" /default_jaas.conf /etc/iris-template/jaas.conf
create_config "site" /default_siteconfig.groovy \
                     /etc/freeipa-pwd-portal-template/siteconfig.groovy

[[ ! -f /default_logback.groovy ]] ||
  mv /default_logback.groovy /etc/freeipa-pwd-portal-template/logback.groovy

source /data_dirs.env
for datadir in "${DATA_DIRS[@]}"; do
  if [ ! -e "${DATA_PATH}/${datadir#/*}" ]
  then
    echo "Installing ${datadir}"
    mkdir -p ${DATA_PATH}/${datadir#/*}
    cp -pr ${datadir}-template/* ${DATA_PATH}/${datadir#/*}/
  fi
done

#
# Set the freeipa-pwd-portal siteconfig location as a permanent
# environment variable
#
[[ -n "$(cat /etc/environment | grep "com.xetus.freeipa.pwdportal.config")" ]] ||
  echo "com.xetus.freeipa.pwdportal.config=\
/etc/freeipa-pwd-portal" >> /etc/environment

#
#   FREEIPA_SSL_CERT - the FreeIPA instance's certificate
#
if [[ -n "$FREEIPA_SSL_CERT" && -e "$FREEIPA_SSL_CERT" ]]; then
  echo "Adding the FreeIPA instance's SSL certificate to the JRE keystore..."
  keytool -import -trustcacerts -noprompt \
          -alias freeipa \
          -file "$FREEIPA_SSL_CERT" \
          -keystore "$JRE_KEYSTORE_PATH" \
          -storepass "$JRE_KEYSTORE_PASS"
fi



echo "Starting the Free IPA Password Portal..."
exec java -jar /opt/freeipa-pwd-portal/freeipa-pwd-portal.war \
     -p 44333 \
     -kf "/tmp/keystore.jks" \
     --keystore-alias "password.port.direct" \
     -kp "password"
