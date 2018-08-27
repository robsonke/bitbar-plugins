#!/bin/bash

#
# Custom script to show the Prometheus alerts
# Uses this api: https://prometheus.io/docs/prometheus/latest/querying/api/
#
PROMETHEUS_HOME=prometheus-server.com
PROMETHEUS_USER=user
PROMETHEUS_PASSWORD=pass
ALERTMANAGER_HOME=alerts.com

ALERTS=$(curl --silent --max-time 2 -X GET https://$PROMETHEUS_USER:$PROMETHEUS_PASSWORD@${PROMETHEUS_HOME}/api/v1/query?query=ALERTS)

if [ -n "$ALERTS" ]; then
  # fetch all failed metrics but skip all with Deployment in the name
  FILTERED=$(echo $ALERTS | /usr/local/bin/jq '[ .data.result[].metric | select(.alertname | contains("Deployment") | not) | select(.severity | tonumber > 1)]')

  NROFFAILURE=$(echo "$FILTERED" | /usr/local/bin/jq 'length')

  if (( $NROFFAILURE > 0 )); then
    ## ohoh trouble
    echo "🔥 ${NROFFAILURE}|color=#f23400 dropdown=false"
    echo "---";
    echo "$FILTERED" | /usr/local/bin/jq -c '.[]' | while read line
    do
      ALERTNAME=$(echo "$line" | /usr/local/bin/jq -r '.alertname')
      NAMESPACE=$(echo "$line" | /usr/local/bin/jq -r '.namespace')
      ALERTSTATE=$(echo "$line" | /usr/local/bin/jq -r '.alertstate')
      INSTANCE=$(echo "$line" | /usr/local/bin/jq -r '.instance')
      # flip severity to priority
      SEVERITY=$(echo "$line" | /usr/local/bin/jq -r '.severity | tonumber | 6 - .')
      MESSAGE="🔥 P$SEVERITY $ALERTNAME "
      if [ ! -z "$NAMESPACE" ] && [ "$NAMESPACE" != "null" ]; then
        MESSAGE="${MESSAGE}($NAMESPACE) "
      fi
      if [ ! -z "$INSTANCE" ] && [ "$INSTANCE" != "null" ]; then
        MESSAGE="${MESSAGE}$INSTANCE "
      fi
      echo "$MESSAGE | color=red href=https://${PROMETHEUS_HOME}/alerts"
    done
    echo ---
    echo "Go to alertmanager | href=https://${ALERTMANAGER_HOME}"
  fi
fi


