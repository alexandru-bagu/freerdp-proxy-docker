#!/bin/sh

# run once and expect segmentation fault
/usr/local/bin/freerdp-proxy /root/config.ini
# run again
/usr/local/bin/freerdp-proxy /root/config.ini