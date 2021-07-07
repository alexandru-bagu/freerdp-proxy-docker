#!/bin/sh

rm -rf server.*
winpr-makecert -rdp -path . server
/usr/local/bin/freerdp-proxy