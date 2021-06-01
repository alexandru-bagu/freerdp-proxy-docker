#!/bin/bash
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

DEBUG=0

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
RESULT=unknown

LOWERUSERNAME="${Username,,}"
if [[ "$LOWERUSERNAME" == "andrewf" ]]; then
  RESULT=172.16.114.171
elif [[ "$LOWERUSERNAME" == "joe" ]]; then
  RESULT=172.16.114.172
elif [[ "$LOWERUSERNAME" == "kyle" ]]; then
  RESULT=172.16.114.173
elif [[ "$LOWERUSERNAME" == "shane" ]]; then
  RESULT=172.16.114.174
elif [[ "$LOWERUSERNAME" == "dave" ]]; then
  RESULT=172.16.114.175
elif [[ "$LOWERUSERNAME" == "james" ]]; then
  RESULT=172.16.114.176
elif [[ "$LOWERUSERNAME" == "liz" ]]; then
  RESULT=172.16.114.177
elif [[ "$LOWERUSERNAME" == "cat" ]]; then
  RESULT=172.16.114.178
elif [[ "$LOWERUSERNAME" == "vdiadmin" ]]; then
  RESULT=172.16.114.179
elif [[ "$LOWERUSERNAME" == "user2" ]]; then
  RESULT=172.16.114.180
fi

# 'printf' instead of 'echo' because echo appends '\n'
printf "$RESULT"