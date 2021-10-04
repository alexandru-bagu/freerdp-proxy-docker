#!/bin/bash

if ! [ -d certificates ]; then
  winpr-makecert -silent -path certificates -n rdp-server -y 100
  winpr-makecert -silent -path certificates -n rdp-private
fi
/usr/local/bin/freerdp-proxy config.ini