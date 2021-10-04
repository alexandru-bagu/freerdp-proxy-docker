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

GUACAMOLE_API="${GUACAMOLE_API:-}"
GUACAMOLE_DB_HOST="${GUACAMOLE_DB_HOST:-}"
GUACAMOLE_DB_USER="${GUACAMOLE_DB_USER:-}"
GUACAMOLE_DB_PASS="${GUACAMOLE_DB_PASS:-}"

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

# extract Apache Guacamole Auth Token and Connection Token from Routing Token:
# example: "Auth: DEEFDCE0375390C69608BBE85435AE419CB3D8F763D34B3858A7E527B3AC9904; Conn: MQBjAG15c3Fs;"

AUTHTOKEN=`echo "$RoutingToken" | grep -P 'Auth: ([a-f]|[A-F]|[0-9])+;' -o | sed "s/Auth: //g" | sed "s/;$//g"`
CONNTOKEN=`echo "$RoutingToken" | grep -P 'Conn: (.*)+;' -o | sed "s/Conn: //g" | sed "s/;$//g"`

# validate Apache Guacamole Auth Token:
AUTHDATA=`curl "$GUACAMOLE_API/tokens" --data "token=$AUTHTOKEN" -s`
AUTHDATA_TOKEN=`echo "$AUTHDATA" | jq -r ".authToken"`

if [[ "$DEBUG" == "1" ]]; then
  printf "AUTHDATA=\"$AUTHDATA\"\n" >&2
  printf "AUTHDATA_TOKEN=\"$AUTHDATA_TOKEN\"\n" >&2
fi

if [ -z "$AUTHDATA_TOKEN" ] || [[ "$AUTHDATA_TOKEN" == "null" ]]; then
  # Apache Guacamole Auth token is not valid
  printf "INVALID AUTHENTICATION DATA\n" >&2
  printf 'invalid data'
  exit 1
elif [[ "$AUTHDATA_TOKEN" == "$AUTHTOKEN" ]]; then
  AUTHDATA_USER=`echo "$AUTHDATA" | jq -r ".username"`
  CONNDATA=`printf "$CONNTOKEN" | base64 -d | tr "\\0" "_"`
  CONN_ID=`printf "$CONNDATA" | sed "s/_.*//g"`
  re='^[0-9]+$'
  if ! [[ $CONN_ID =~ $re ]] || [ -z "$CONN_ID" ]; then
    CONN_ID=0 # ensure conn_id is number
  fi
  CONN_TYPE=`printf "$CONNDATA" | sed "s/${CONN_ID}_//g" | sed "s/_.*//g"`
  CONN_SRC=`printf "$CONNDATA" | sed "s/${CONN_ID}_${CONN_TYPE}_//g" | sed "s/_.*//g"`

  API_CONNDATA=`curl "$GUACAMOLE_API/session/data/$CONN_SRC/connectionGroups/ROOT/tree?token=$AUTHTOKEN" -s`
  if [[ "$DEBUG" == "1" ]]; then
    printf "API_CONNDATA=\"$API_CONNDATA\"\n" >&2
  fi
  ALLOWED_CONN_IDS="`echo $API_CONNDATA | jq ".childConnections[] .identifier" -r 2>/dev/null`
`echo $API_CONNDATA | jq ".childConnectionGroups[] .childConnections[] .identifier" -r 2>/dev/null`"
  ALLOWED_CONN_IDS="`echo "$ALLOWED_CONN_IDS" | sed '/^$/d' | tr '\n' ' '`"
  if [[ "$DEBUG" == "1" ]]; then
    printf "ALLOWED_CONN_IDS=\"$ALLOWED_CONN_IDS\"\n" >&2
  fi

  read -a ALLOWED_CONN_IDS_ARRAY <<< "$ALLOWED_CONN_IDS"

  if [[ "$CONN_ID" == "0" ]]; then # select first allowed connection
    CONN_ID="${ALLOWED_CONN_IDS_ARRAY[0]}"
  fi

  VALID=0
  for FOR_CONN_ID in "${ALLOWED_CONN_IDS_ARRAY[@]}"
  do
    if [ "$FOR_CONN_ID" == "$CONN_ID" ]; then
      VALID=1
    fi
  done

  if [ "$VALID" == "0" ]; then
    if [[ "$DEBUG" == "1" ]]; then
      printf "CONNECTION NOT ALLOWED FOR USER: $CONN_ID; ALLOWED: $ALLOWED_CONN_IDS\n" >&2
    fi
    exit 1
  fi

  CONN_HOST=
  CONN_PORT=
  CLIPBOARD_DISABLED=false
  SHARED_DRIVES_ENABLED=false
  PRINTING_ENABLED=false
  PNP_ENABLED=true
  USB_REDIRECT_ENABLED=true
  if [[ "$CONN_SRC" == "mysql" ]]; then
    while read LINE; do
      PNAME=`printf "$LINE" | sed "s/\t.*//g"`
      PVAL=`printf "$LINE" | sed "s/$PNAME\t//g"`
      if [[ "$PNAME" == "hostname" ]]; then
        CONN_HOST="$PVAL"
      elif [[ "$PNAME" == "port" ]]; then
        CONN_PORT="$PVAL"
      elif [[ "$PNAME" == "disable-copy" ]] && [[ "$PVAL" == "true" ]]; then
        CLIPBOARD_DISABLED="$PVAL"
      elif [[ "$PNAME" == "disable-paste" ]] && [[ "$PVAL" == "true" ]]; then
        CLIPBOARD_DISABLED="$PVAL"
      elif [[ "$PNAME" == "enable-drive" ]] && [[ "$PVAL" == "true" ]]; then
        SHARED_DRIVES_ENABLED="$PVAL"
      elif [[ "$PNAME" == "enable-printing" ]] && [[ "$PVAL" == "true" ]]; then
        PRINTING_ENABLED="$PVAL"
      fi
    done <<< "`mysql -h"$GUACAMOLE_DB_HOST" -u"$GUACAMOLE_DB_USER" -p"$GUACAMOLE_DB_PASS" guac_db -N -s -e \"SELECT GCPA.parameter_name,GCPA.parameter_value FROM guacamole_connection_parameter GCPA \
      INNER JOIN guacamole_connection GC ON GC.connection_id = GCPA.connection_id \
      WHERE GCPA.connection_id = $CONN_ID AND GC.protocol = 'rdp'\"`"
    #`

    if [ -z "$CONN_PORT" ]; then
      TARGET_IP="$CONN_HOST"
    else
      TARGET_IP="$CONN_HOST"
      TARGET_PORT="$CONN_PORT"
    fi
  fi
fi

# a list of comma seperated static channels that will be proxied
# "rdpdr": [MS-RDPEFS] support for remote/shared file system
# "PNPDR": [MS-RDPEPNP] support for plug'n'play devices 
# "URBDRC": [MS-RDPEUSB] support for usb redirection; requires PNPDR
# "XPSRD": [MS-RDPEXPS] support for printers; available with rdpdr
# "RDCamera_Device_Enumerator": [MS-RDPECAM] support for remote video capture devices
# "RDCamera_Device_0": [MS-RDPECAM]
# "FileRedirectorChannel": [MS-RDPEPNP] passthrough file redirection for PNPDR

CHANNEL_BLACKLIST=""

if ! ( [[ "$SHARED_DRIVES_ENABLED" == "true" ]] || [[ "$PRINTING_ENABLED" == "true" ]] ); then
  CHANNEL_BLACKLIST="rdpdr,$CHANNEL_BLACKLIST"
fi
if ! ( [[ "$PRINTING_ENABLED" == "true" ]] ); then
  CHANNEL_BLACKLIST="XPSRD,$CHANNEL_BLACKLIST"
fi
if ! ( [[ "$PNP_ENABLED" == "true" ]] || [[ "$USB_REDIRECT_ENABLED" == "true" ]] ); then
  CHANNEL_BLACKLIST="PNPDR,$CHANNEL_BLACKLIST"
fi
if ! ( [[ "$USB_REDIRECT_ENABLED" == "true" ]] ); then
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
Clipboard=`if [[ "$CLIPBOARD_DISABLED" == "false" ]]; then echo "FALSE"; else echo "true"; fi`
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
EOF