#!/bin/bash

#
# Custom script to show the Statuscake.com tests that are currently down
# uses the jq command line json parser
#


API_KEY="yourapikey"
USERNAME="yourusername"

# get down tests
TESTS=$(curl --silent -H "API: ${API_KEY}" -H "Username: ${USERNAME}" -X GET https://app.statuscake.com/API/Tests/)


if [ "$TESTS" == "[]" ]; then
  NROFDOWN=0
else
  # get all test id's, filtered by paused = false as the api can't do that
  TESTIDS=$(echo $TESTS | /usr/local/bin/jq '.[] | select(.Paused == false) | select(.Status == "Down") | .TestID')
  NROFPAUSED=$(echo $TESTS | /usr/local/bin/jq '[.[] | select(.Paused == true)] | length')
  # count the number of tests, skip empty lines
  NROFDOWN=$(echo "$TESTIDS" | sed '/^\s*$/d' | wc -l | xargs)
fi

if [ $NROFDOWN -gt 0 ] || [ $NROFPAUSED -gt 0 ]; then
  # NAMES=$(echo $TESTS | /usr/local/bin/jq '.[] | select(.Paused == false) | .WebsiteName')
  # URLS=$(echo $TESTS | /usr/local/bin/jq '.[] | select(.Paused == false) | .WebsiteURL')

  TEXT=""
  if [ $NROFPAUSED -gt 0 ]; then
    TEXT=" (P:${NROFPAUSED})"
  fi
  if [ $NROFDOWN -gt 0 ]; then
    TEXT="🍰 ${NROFDOWN}⇩${TEXT}|color=#f23400 dropdown=false"
  else
    # means only paused ones
    TEXT="🍰 ${NROFPAUSED}|dropdown=false"
  fi

  echo $TEXT
  if [ $NROFDOWN -gt 0 ] || [ $NROFPAUSED -gt 0 ]; then
    echo "---";
    for test in $(echo "${TESTS}" | /usr/local/bin/jq -r '.[] | @base64'); do
      _jq() {
        echo ${test} | base64 --decode | /usr/local/bin/jq -r ${1}
      }
      if [ $(_jq '.Status') == "Down" ] || [ $(_jq '.Paused') == true ]; then
        URL=$(_jq '.WebsiteURL')
        echo "$(_jq '.WebsiteName') ($URL) | color=red href=$URL"
      fi
    done
  fi
  echo ---
  echo "Refresh the test list | refresh=true"
  echo "Go to StatusCake | href=https://app.statuscake.com/YourStatus.php"
fi
