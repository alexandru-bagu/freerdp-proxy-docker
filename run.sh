#!/bin/sh

docker build . -t bssone/freerdp-proxy-guacamole-auth:latest
docker run -it -p 3389:3389/tcp bssone/freerdp-proxy-guacamole-auth:latest