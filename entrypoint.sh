#!/bin/bash

if ! [ -d certificates ]; then
  winpr-makecert -silent -path certificates -n rdp-server -y 100
  winpr-makecert -silent -path certificates -n rdp-private
fi
if [ -f "$CERTIFICATE_CRT" ] && [ -f "$CERTIFICATE_KEY" ]; then
  sed -i.bak "s|^CertificateFile=.*|CertificateFile=$CERTIFICATE_CRT|g" config.ini
  sed -i.bak "s|^PrivateKeyFile=.*|PrivateKeyFile=$CERTIFICATE_KEY|g" config.ini
else
  sed -i.bak "s|^CertificateFile=.*|CertificateFile=/root/certificates/rdp-server.crt|g" config.ini
  sed -i.bak "s|^PrivateKeyFile=.*|PrivateKeyFile=/root/certificates/rdp-server.key|g" config.ini
fi
/usr/local/bin/freerdp-proxy config.ini