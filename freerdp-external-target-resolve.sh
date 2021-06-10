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
RESULT=

# extract Apache Guacamole Auth Token and Connection Token from Routing Token:
# example: "Auth: DEEFDCE0375390C69608BBE85435AE419CB3D8F763D34B3858A7E527B3AC9904; Conn: MQBjAG15c3Fs;"

AUTHTOKEN=`echo "$RoutingToken" | grep -P 'Auth: ([a-f]|[A-F]|[0-9])+;' -o | sed "s/Auth: //g" | sed "s/;$//g"`
CONNTOKEN=`echo "$RoutingToken" | grep -P 'Conn: (.*)+;' -o | sed "s/Conn: //g" | sed "s/;$//g"`

# validate Apache Guacamole Auth Token:
AUTHDATA=`curl "$GUACAMOLE_API/tokens" --data "token=$AUTHTOKEN" -s`
AUTHDATA_TOKEN=`echo "$AUTHDATA" | jq -r ".authToken"`
if echo "$AUTHDATA_TOKEN" | grep -q "$AUTHTOKEN"; then
  AUTHDATA_USER=`echo "$AUTHDATA" | jq -r ".username"`
  CONNDATA=`printf "$CONNTOKEN" | base64 -d | tr "\\0" "_"`
  CONN_ID=`printf "$CONNDATA" | sed "s/_.*//g"`
  re='^[0-9]+$'
  if ! [[ $CONN_ID =~ $re ]] || [ -z "$CONN_ID" ]; then
    CONN_ID=0 # ensure conn_id is number
  fi
  CONN_TYPE=`printf "$CONNDATA" | sed "s/${CONN_ID}_//g" | sed "s/_.*//g"`
  CONN_SRC=`printf "$CONNDATA" | sed "s/${CONN_ID}_${CONN_TYPE}_//g" | sed "s/_.*//g"`

  if [[ "$CONN_ID" == "0" ]]; then # select first allowed connection
    CONN_ID=`mysql -h"$GUACAMOLE_DB_HOST" -u"$GUACAMOLE_DB_USER" -p"$GUACAMOLE_DB_PASS" guac_db -N -s -e "SELECT GC.connection_id FROM guacamole_entity GE \
INNER JOIN guacamole_user GU ON GU.entity_id = GE.entity_id \
INNER JOIN guacamole_connection_permission GCP ON GCP.entity_id = GE.entity_id \
INNER JOIN guacamole_connection GC ON GC.connection_id = GCP.connection_id AND GC.protocol = 'rdp' \
WHERE GE.name ='$AUTHDATA_USER' AND GE.type ='USER' LIMIT 1"`
    CONN_SRC="mysql"
  fi

  CONN_HOST=
  CONN_PORT=
  if [[ "$CONN_SRC" == "mysql" ]]; then
    while read LINE; do
      PNAME=`printf "$LINE" | sed "s/\t.*//g"`
      PVAL=`printf "$LINE" | sed "s/$PNAME\t//g"`
      if [[ "$PNAME" == "hostname" ]]; then
        CONN_HOST="$PVAL"
      elif [[ "$PNAME" == "port" ]]; then
        CONN_PORT="$PVAL"
      fi
    done <<< "`mysql -h"$GUACAMOLE_DB_HOST" -u"$GUACAMOLE_DB_USER" -p"$GUACAMOLE_DB_PASS" guac_db -N -s -e \"SELECT GCPA.parameter_name,GCPA.parameter_value FROM guacamole_entity GE \
      INNER JOIN guacamole_user GU ON GU.entity_id = GE.entity_id \
      INNER JOIN guacamole_connection_permission GCP ON GCP.entity_id = GE.entity_id \
      INNER JOIN guacamole_connection GC ON GC.connection_id = GCP.connection_id \
      INNER JOIN guacamole_connection_parameter GCPA ON GCPA.connection_id = GC.connection_id \
      WHERE GE.name ='$AUTHDATA_USER' AND GE.type ='USER' AND GCP.connection_id = $CONN_ID AND GC.protocol = 'rdp'\"`"
    #`

    if [ -z "$CONN_PORT" ]; then
      RESULT="$CONN_HOST"
    else
      RESULT="$CONN_HOST:$CONN_PORT"
    fi
  fi
else
  # Apache Guacamole Auth token is not valid
  exit 1
fi

    
if [[ "$DEBUG" == "1" ]]; then
    printf "Result=$RESULT\n" >&2
fi

# 'printf' instead of 'echo' because echo appends '\n'
printf "$RESULT"