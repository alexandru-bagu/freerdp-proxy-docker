#!/bin/sh

docker build . -t bssone/freerdp-proxy-guacamole-auth:latest
docker run -v "$(pwd)/cert:/external" \
  -e "CERTIFICATE_CRT=/external/cert.pem" \
  -e "CERTIFICATE_KEY=/external/key.pem" \
  -it -p 3389:3389/tcp bssone/freerdp-proxy-guacamole-auth:latest