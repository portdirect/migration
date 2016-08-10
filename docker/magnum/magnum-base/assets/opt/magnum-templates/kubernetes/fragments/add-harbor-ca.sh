#cloud-boothook
#!/bin/sh

IPA_CA_CRT={{IPA_CA_CRT}}

mkdir -p /etc/pki/ca-trust/source/anchors/
echo $IPA_CA_CRT | base64 --decode > /etc/pki/ca-trust/source/anchors/ipa.crt

update-ca-trust
