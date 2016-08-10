#!/bin/bash
set -e

PATH=${PATH}:/usr/local/bin


IPA_ADMIN_USER=admin
IPA_ADMIN_PASSWORD=OTkzMjQ3NmRiZGQ2NWI0OWRjYTAwNzFiYmRkMWY1ZjFhZjFkMjMwMGFmOTI4YzMyODE4MTI2OTk5MmQzZGE2MmI5ZTM3ODQzYmUwMGFmOTE2ZmQwNTU0ZWI3MmViZTUz


systemctl enable certmonger
systemctl restart certmonger

mkdir -p /etc/harbor
cat > /etc/harbor/pub-ca.crt <<EOF
-----BEGIN CERTIFICATE-----
MIIGCDCCA/CgAwIBAgIQKy5u6tl1NmwUim7bo3yMBzANBgkqhkiG9w0BAQwFADCB
hTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxKzApBgNV
BAMTIkNPTU9ETyBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTQwMjEy
MDAwMDAwWhcNMjkwMjExMjM1OTU5WjCBkDELMAkGA1UEBhMCR0IxGzAZBgNVBAgT
EkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMR
Q09NT0RPIENBIExpbWl0ZWQxNjA0BgNVBAMTLUNPTU9ETyBSU0EgRG9tYWluIFZh
bGlkYXRpb24gU2VjdXJlIFNlcnZlciBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEP
ADCCAQoCggEBAI7CAhnhoFmk6zg1jSz9AdDTScBkxwtiBUUWOqigwAwCfx3M28Sh
bXcDow+G+eMGnD4LgYqbSRutA776S9uMIO3Vzl5ljj4Nr0zCsLdFXlIvNN5IJGS0
Qa4Al/e+Z96e0HqnU4A7fK31llVvl0cKfIWLIpeNs4TgllfQcBhglo/uLQeTnaG6
ytHNe+nEKpooIZFNb5JPJaXyejXdJtxGpdCsWTWM/06RQ1A/WZMebFEh7lgUq/51
UHg+TLAchhP6a5i84DuUHoVS3AOTJBhuyydRReZw3iVDpA3hSqXttn7IzW3uLh0n
c13cRTCAquOyQQuvvUSH2rnlG51/ruWFgqUCAwEAAaOCAWUwggFhMB8GA1UdIwQY
MBaAFLuvfgI9+qbxPISOre44mOzZMjLUMB0GA1UdDgQWBBSQr2o6lFoL2JDqElZz
30O0Oija5zAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNV
HSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwGwYDVR0gBBQwEjAGBgRVHSAAMAgG
BmeBDAECATBMBgNVHR8ERTBDMEGgP6A9hjtodHRwOi8vY3JsLmNvbW9kb2NhLmNv
bS9DT01PRE9SU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDBxBggrBgEFBQcB
AQRlMGMwOwYIKwYBBQUHMAKGL2h0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9E
T1JTQUFkZFRydXN0Q0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21v
ZG9jYS5jb20wDQYJKoZIhvcNAQEMBQADggIBAE4rdk+SHGI2ibp3wScF9BzWRJ2p
mj6q1WZmAT7qSeaiNbz69t2Vjpk1mA42GHWx3d1Qcnyu3HeIzg/3kCDKo2cuH1Z/
e+FE6kKVxF0NAVBGFfKBiVlsit2M8RKhjTpCipj4SzR7JzsItG8kO3KdY3RYPBps
P0/HEZrIqPW1N+8QRcZs2eBelSaz662jue5/DJpmNXMyYE7l3YphLG5SEXdoltMY
dVEVABt0iN3hxzgEQyjpFv3ZBdRdRydg1vs4O2xyopT4Qhrf7W8GjEXCBgCq5Ojc
2bXhc3js9iPc0d1sjhqPpepUfJa3w/5Vjo1JXvxku88+vZbrac2/4EjxYoIQ5QxG
V/Iz2tDIY+3GH5QFlkoakdH368+PUq4NCNk+qKBR6cGHdNXJ93SrLlP7u3r7l+L4
HyaPs9Kg4DdbKDsx5Q5XLVq4rXmsXiBmGqW5prU5wfWYQ//u+aen/e7KJD2AFsQX
j4rBYKEMrltDR5FL1ZoXX/nUh8HCjLfn4g8wGTeGrODcQgPmlKidrv0PJFGUzpII
0fxQ8ANAe4hZ7Q7drNJ3gjTcBpUC2JD5Leo31Rpg0Gcg19hCC0Wvgmje3WYkN5Ap
lBlGGSW4gNfL1IYoakRwJiNiqZ+Gb7+6kHDSVneFeO/qJakXzlByjAA6quPbYzSf
+AZxAeKCINT+b72x
-----END CERTIFICATE-----
EOF
cat /etc/harbor/pub-ca.crt >> /etc/ssl/certs/ca-bundle.crt

curl -L https://freeipa-master.port.direct/ipa/config/ca.crt > /etc/harbor/ipa-ca.crt


cat /etc/harbor/ipa-ca.crt > /etc/harbor/ca-bundle.crt
cat /etc/harbor/pub-ca.crt >> /etc/harbor/ca-bundle.crt

source /etc/harbor/network.env
ETCD_NETWORK_EXT_IP=$(dig +short etcd-network.port.direct @${EXTERNAL_DNS})
echo "${ETCD_NETWORK_EXT_IP} etcd-network.${OS_DOMAIN} etcd-network" >> /etc/hosts
cat > /etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
169.254.169.254 metadata.google.internal
${ETCD_NETWORK_EXT_IP} etcd-network.${OS_DOMAIN} etcd-network
127.0.0.1 $(hostname -s).${OS_DOMAIN} $(hostname -s)
EOF
echo "nameserver ${EXTERNAL_DNS}" > /etc/resolv.conf
echo "nameserver ${EXTERNAL_DNS_1}" >> /etc/resolv.conf

ssh-keygen -A
ipa-client-install \
   --hostname=$(hostname -s).${OS_DOMAIN} \
   --domain=${OS_DOMAIN} \
   --request-cert \
   --no-ntp \
   --force-join \
   --unattended \
   --enable-dns-updates \
   --ca-cert-file="/etc/harbor/ca-bundle.crt" \
   --principal="${IPA_ADMIN_USER}" \
   --password="${IPA_ADMIN_PASSWORD}"

systemctl enable certmonger
systemctl restart certmonger


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



#From the certificates we have generated, we can produce a kubeconfig file that kubernetes components will use to authenticate against the api server:
SVC_HOST_NAME=kubelet
SVC_AUTH_ROOT_HOST=/etc/harbor/auth
mkdir -p ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}
cat ${HOST_SVC_CA_LOC} > ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/ca.crt
cat > ${SVC_AUTH_ROOT_HOST}/${SVC_HOST_NAME}/kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
users:
- name: kubelet
  user:
    client-certificate-data: $( cat ${SVC_AUTH_ROOT_HOST}/host/host.crt | base64 --wrap=0)
    client-key-data: $( cat ${SVC_AUTH_ROOT_HOST}/host/host.key | base64 --wrap=0)
clusters:
- name: $(echo ${OS_DOMAIN} | tr '.' '-')
  cluster:
    certificate-authority-data: $(cat ${SVC_AUTH_ROOT_HOST}/host/ca.crt | base64 --wrap=0)
contexts:
- context:
    cluster: $(echo ${OS_DOMAIN} | tr '.' '-')
    user: kubelet
  name: service-account-context
current-context: service-account-context
EOF
