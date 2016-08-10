#!/bin/bash
set -e
PATH=${PATH}:/usr/local/bin
source /etc/harbor/network.env
source /etc/harbor/auth.env

systemctl enable certmonger
systemctl restart certmonger

ipa-client-install \
   --hostname=$(hostname -s).${OS_DOMAIN} \
   --enable-dns-updates \
   --request-cert \
   --no-ntp \
   --force-join \
   --unattended \
   --principal="${IPA_ADMIN_USER}" \
   --password="${IPA_ADMIN_PASSWORD}"

sleep 20s
systemctl restart certmonger
sleep 60s

SVC_AUTH_ROOT_HOST=/etc/harbor/auth
SVC_HOST_NAME=$(hostname -s)
mkdir -p ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}
HOST_SVC_KEY_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.key
HOST_SVC_CRT_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/${SVC_HOST_NAME}.crt
HOST_SVC_CA_LOC=${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt

until certutil -K -d /etc/ipa/nssdb -a -f /etc/ipa/nssdb/pwdfile.txt; do
   echo "Waiting for Certs"
   sleep 5
done

until pk12util -o /tmp/keys.p12 -n 'Local IPA host' -d /etc/ipa/nssdb -w /etc/ipa/nssdb/pwdfile.txt -k /etc/ipa/nssdb/pwdfile.txt; do
   echo "Waiting for Certs"
   sleep 5
done

openssl pkcs12 -in /tmp/keys.p12 -out ${HOST_SVC_KEY_LOC} -nocerts -nodes -passin file:/etc/ipa/nssdb/pwdfile.txt -passout pass:
openssl pkcs12 -in /tmp/keys.p12 -out ${HOST_SVC_CRT_LOC} -clcerts -passin file:/etc/ipa/nssdb/pwdfile.txt -passout pass:
openssl pkcs12 -in /tmp/keys.p12 -out ${HOST_SVC_CA_LOC} -cacerts -passin file:/etc/ipa/nssdb/pwdfile.txt -passout pass:
rm -rf /tmp/keys.p12

mkdir -p ${SVC_AUTH_ROOT_HOST}/host
cat ${HOST_SVC_KEY_LOC} > ${SVC_AUTH_ROOT_HOST}/host/host.key
cat ${HOST_SVC_CRT_LOC} > ${SVC_AUTH_ROOT_HOST}/host/host.crt
cat ${HOST_SVC_CA_LOC} > ${SVC_AUTH_ROOT_HOST}/host/ca.crt

mkdir -p ${SVC_AUTH_ROOT_HOST}/host/messaging
cat ${HOST_SVC_KEY_LOC} > ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging.key
cat ${HOST_SVC_CRT_LOC} > ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging.crt
cat ${HOST_SVC_CA_LOC} > ${SVC_AUTH_ROOT_HOST}/host/messaging/messaging-ca.crt

mkdir -p ${SVC_AUTH_ROOT_HOST}/host/database
cat ${HOST_SVC_KEY_LOC} > ${SVC_AUTH_ROOT_HOST}/host/database/database.key
cat ${HOST_SVC_CRT_LOC} > ${SVC_AUTH_ROOT_HOST}/host/database/database.crt
cat ${HOST_SVC_CA_LOC} > ${SVC_AUTH_ROOT_HOST}/host/database/database-ca.crt
