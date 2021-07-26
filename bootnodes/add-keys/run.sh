#!/bin/sh
set -ex
for i in /chain/keys/*.json; do
  idx="${i//[!0-9]/}"
  host=$(echo "$1_${idx}_internal_service_host" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  port=$(echo "$1_${idx}_internal_service_port_rpc" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  eval "host_port=\$$host:\$$port"
  retry=0
  until [ "$retry" -ge 3 ]; do
      # code=$(curl -H "Content-Type: application/json" -d @$i -v $host_port)
      code=$(curl -H "Content-Type: application/json" -d @$i -s -L -o /dev/null -w "%{http_code}\n" $host_port)
      if [ "200" -eq "$code" ]; then
          break
      fi
      retry=$((retry+1))
      sleep 5
  done
done