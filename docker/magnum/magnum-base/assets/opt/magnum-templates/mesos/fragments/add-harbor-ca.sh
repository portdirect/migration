#cloud-boothook
#!/bin/sh

IPA_CA_CRT={{IPA_CA_CRT}}

mkdir -p /usr/local/share/ca-certificates/
echo $IPA_CA_CRT | base64 --decode > /usr/local/share/ca-certificates/ipa.crt

update-ca-certificates

rm -f /opt/stack/venvs/os-collect-config/local/lib/python2.7/site-packages/requests/cacert.pem
ln -s /etc/ssl/certs/ca-certificates.crt /opt/stack/venvs/os-collect-config/local/lib/python2.7/site-packages/requests/cacert.pem

  #!/bin/sh
cat > /usr/local/share/ca-certificates/ipa.crt << EOF
-----BEGIN CERTIFICATE-----
MIIDljCCAn6gAwIBAgIBATANBgkqhkiG9w0BAQsFADA2MRQwEgYDVQQKDAtQT1JU
LkRJUkVDVDEeMBwGA1UEAwwVQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTE2MDQw
MzAwMTUxMVoXDTM2MDQwMzAwMTUxMVowNjEUMBIGA1UECgwLUE9SVC5ESVJFQ1Qx
HjAcBgNVBAMMFUNlcnRpZmljYXRlIEF1dGhvcml0eTCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAJ5/cIikfGrkElHkZypN1jHlXjH+LZVvdUh0MHuvfBZe
USp04AGNIWz4ItoEHckjHdnLNLGiUmR1qfuJLfpmLe4WAhek6zyyWUWyNCvKI6lY
mBJ1dU7IX0CSsZ/1yn9i8aZO3ikQC3HqXu3xnDNPd92HaGZf+gb4w+LndQhwmDgf
8+trTqNZ+f8rOHupw1xKJWRyJQ3S2KikDgXG5/D3xbbGFF+T4zKnvZb8r5X2hi7+
C3pVvAOEMBiJqt4voXh1MXpGAJVCf7bIOJ4LK9YVPsBSj7M+djk4YQxeAlKskXdu
k0yRhmQzeyy/2UpvVo63f03I36smWY9BJkzeS0f2WVMCAwEAAaOBrjCBqzAfBgNV
HSMEGDAWgBSeKy+tVJ4PKoFTmMOeClHZJBXYwTAPBgNVHRMBAf8EBTADAQH/MA4G
A1UdDwEB/wQEAwIBxjAdBgNVHQ4EFgQUnisvrVSeDyqBU5jDngpR2SQV2MEwSAYI
KwYBBQUHAQEEPDA6MDgGCCsGAQUFBzABhixodHRwOi8vZnJlZWlwYS1tYXN0ZXIu
cG9ydC5kaXJlY3Q6ODAvY2Evb2NzcDANBgkqhkiG9w0BAQsFAAOCAQEAgp5+EPgT
kHQ0xIJyzcAnzTpyWuMuZH0ogHlM2r7c+Q3NgGjgDQvmgbKF8/9upJHceV3ujNaA
86u7u1croUPJlFFA4/kmJYdnaJJmMTBgMRC8Dl65oOw1KpHUQHl9s4NK1URd19Ky
2MLgpjBzr3FcYw604gxw5QwArzyDIuNZCXSSlGMAxnZq1ymQoOLCS3mfUHnNheVS
k/ViKzKbFHLX3Oi/lDS9drc7V6fdKiVSPctwsiNU/oqR3EphZudKA0lbRsf/yCdY
iCkKaD+IeHnniEeuSc6QHu7C2DC+I8LeaktdR+Zk0KmUrG0CV9PaiCUZnIpqIABQ
+cCYKFnX+jiO7w==
-----END CERTIFICATE-----
EOF
update-ca-certificates


rm -f /opt/stack/venvs/os-collect-config/local/lib/python2.7/site-packages/requests/cacert.pem
ln -s /etc/ssl/certs/ca-certificates.crt /opt/stack/venvs/os-collect-config/local/lib/python2.7/site-packages/requests/cacert.pem
