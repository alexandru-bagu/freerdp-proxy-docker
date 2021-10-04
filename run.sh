#!/bin/sh

docker build . -t freerdp-proxy-auth
docker run -it -p 3389:3389/tcp freerdp-proxy-auth