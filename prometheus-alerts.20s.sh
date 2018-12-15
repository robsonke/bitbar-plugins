#!/bin/bash
#
# Custom script to show the Prometheus alerts
#
PROMETHEUS_HOME=prometheus-server.com
PROMETHEUS_USER=user
PROMETHEUS_PASSWORD=pass
ALERTMANAGER_HOME=alerts.com

ALERTS=$(curl --silent --max-time 2 -X GET https://$PROMETHEUS_USER:$PROMETHEUS_PASSWORD@${ALERTMANAGER_PROXY}/api/v1/alerts?silenced=true)

if [ -n "$ALERTS" ]; then
  # remove select( .labels.schema != "NWSROOMPOT_STAGING" but for now to supress old errors
  HIGHPRIO=$(echo $ALERTS | /usr/local/bin/jq '[ .data[] | select(.labels.severity | tonumber < 2) | select( .labels.schema != "NWSROOMPOT_STAGING" )] | sort_by(.annotations.summary)')
  NROFHIGHPRIO=$(echo "$HIGHPRIO" | /usr/local/bin/jq 'length')

  NORMALPRIO=$(echo $ALERTS | /usr/local/bin/jq '[ .data[] | select(.labels.severity | tonumber > 1)] | sort_by(.annotations.summary)')
  NROFNORMALPRIO=$(echo "$NORMALPRIO" | /usr/local/bin/jq 'length')

  #echo $NORMALPRIO | /usr/local/bin/jq '.'

  COLOR="white"
  if (( $NROFHIGHPRIO > 0 )); then
    # ohoh trouble
    MAINTEXT="🔥 ${NROFHIGHPRIO} "
    COLOR="#f23400"
  fi
  if (( $NROFNORMALPRIO > 0 )); then
    # less trouble
    MAINTEXT=${MAINTEXT}"❕${NROFNORMALPRIO}"
  fi
  echo ${MAINTEXT}" | color=${COLOR} dropdown=false"

  # below could be extended with silencing info from:
  # https://alerts-prod-proxy.maxxton.com/api/v1/silence/36e73791-b34b-4d74-a4e1-b79dd2db71ae

  # populate submenu with all issues
  echo "---";
  echo "$HIGHPRIO" | /usr/local/bin/jq -c '.[]' | while read line
  do
    SUMMARY=$(echo "$line" | /usr/local/bin/jq -r '.annotations.summary')
    NAMESPACE=$(echo "$line" | /usr/local/bin/jq -r '.labels.namespace')
    STATUS=$(echo "$line" | /usr/local/bin/jq -r '.status.state')
    SILENCED=""
    if [ "$STATUS" == "suppressed" ]; then
      SILENCED=🔕
    fi

    if [ ! -z "$NAMESPACE" ] && [ "$NAMESPACE" != "null" ]; then
      echo "🔥 $SILENCED $SUMMARY ($NAMESPACE}) | color=red href=https://${PROMETHEUS_HOME}/alerts"
    else
      echo "🔥 $SILENCED $SUMMARY | color=red href=https://${PROMETHEUS_HOME}/alerts"
    fi
  done
  echo ---
  echo "$NORMALPRIO" | /usr/local/bin/jq -c '.[]' | while read line
  do
    SUMMARY=$(echo "$line" | /usr/local/bin/jq -r '.annotations.summary')
    NAMESPACE=$(echo "$line" | /usr/local/bin/jq -r '.labels.namespace')
    STATUS=$(echo "$line" | /usr/local/bin/jq -r '.status.state')
    SILENCED=""
    if [ "$STATUS" == "suppressed" ]; then
      SILENCED=🔕
    fi

    if [ ! -z "$NAMESPACE" ] && [ "$NAMESPACE" != "null" ]; then
      echo "❕ $SILENCED $SUMMARY ($NAMESPACE}) | href=https://${PROMETHEUS_HOME}/alerts"
    else
      echo "❕ $SILENCED $SUMMARY | href=https://${PROMETHEUS_HOME}/alerts"
    fi
  done
  echo ---
  echo "Go to alertmanager | href=https://${ALERTMANAGER_HOME}"
fi


