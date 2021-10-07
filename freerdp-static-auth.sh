#!/bin/bash

# dependency binaries: mysql jq

Username="${FreeRDP_Username:-}"
ProxyUsername="${FreeRDP_ProxyUsername:-}"
GatewayUsername="${FreeRDP_GatewayUsername:-}"
Domain="${FreeRDP_Domain:-}"
GatewayDomain="${FreeRDP_GatewayDomain:-}"
Password="${FreeRDP_Password:-}"
ProxyPassword="${FreeRDP_ProxyPassword:-}"
GatewayPassword="${FreeRDP_GatewayPassword:-}"
ClientHostname="${FreeRDP_ClientHostname:-}"
ProxyHostname="${FreeRDP_ProxyHostname:-}"
GatewayHostname="${FreeRDP_GatewayHostname:-}"
RoutingToken="${FreeRDP_RoutingToken:-}"

DEBUG="${DEBUG:-0}"

if [[ "$DEBUG" == "1" ]]; then
  printf "Username=$Username\n" >&2 
  printf "ProxyUsername=$ProxyUsername\n" >&2 
  printf "GatewayUsername=$GatewayUsername\n" >&2 
  printf "Domain=$Domain\n" >&2 
  printf "GatewayDomain=$GatewayDomain\n" >&2 
  printf "Password=$Password\n" >&2 
  printf "ProxyPassword=$ProxyPassword\n" >&2 
  printf "GatewayPassword=$GatewayPassword\n" >&2 
  printf "ClientHostname=$ClientHostname\n" >&2 
  printf "ProxyHostname=$ProxyHostname\n" >&2 
  printf "GatewayHostname=$GatewayHostname\n" >&2 
  printf "RoutingToken=$RoutingToken\n" >&2
fi

# returning an invalid name will effectively disable the connection
TARGET_IP=CustomHost
TARGET_PORT=3389
ALLOW_SHARED_DRIVES_OR_PRINTING=false
ALLOW_PRINTING=false
ALLOW_PLUG_N_PLAY=false
ALLOW_USB_REDIRECT=false
ALLOW_CLIPBOARD=false

CHANNEL_BLACKLIST=""
if ! ( [[ "$ALLOW_SHARED_DRIVES_OR_PRINTING" == "true" ]] ); then
  CHANNEL_BLACKLIST="rdpdr,$CHANNEL_BLACKLIST"
fi
if ! ( [[ "$ALLOW_PRINTING" == "true" ]] ); then
  CHANNEL_BLACKLIST="XPSRD,$CHANNEL_BLACKLIST"
fi
if ! ( [[ "$ALLOW_PLUG_N_PLAY" == "true" ]] || [[ "$ALLOW_USB_REDIRECT" == "true" ]] ); then
  CHANNEL_BLACKLIST="PNPDR,$CHANNEL_BLACKLIST"
fi
if ! ( [[ "$ALLOW_USB_REDIRECT" == "true" ]] ); then
  CHANNEL_BLACKLIST="URBDRC,$CHANNEL_BLACKLIST"
fi
CHANNEL_BLACKLIST="`echo "$CHANNEL_BLACKLIST" | sed s/,$//g`"

cat <<EOF
[Target]
Host = $TARGET_IP
Port = $TARGET_PORT
FixedTarget=true

[Channels]
GFX=true
DisplayControl=true
Clipboard=$ALLOW_CLIPBOARD
AudioInput=true
AudioOutput=true
DeviceRedirection=true
VideoRedirection=true
CameraRedirection=true
RemoteApp=true
PassthroughIsBlacklist=true
Passthrough=$CHANNEL_BLACKLIST

[Input]
Keyboard=true
Mouse=true
Multitouch=true

[Clipboard]
TextOnly=false
MaxTextLength=0

[GFXSettings]
DecodeGFX=false

[Certificates]
CertificateContent=NONE
PrivateKeyContent=NONE
RdpKeyContent=NONE

[Security]
ServerTlsSecurity=true
ServerNlaSecurity=false
ServerRdpSecurity=true
ClientTlsSecurity=true
ClientNlaSecurity=true
ClientRdpSecurity=true
ClientAllowFallbackToTls=true
EOF
