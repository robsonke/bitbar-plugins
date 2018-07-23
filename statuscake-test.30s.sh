#!/bin/bash

#
# Custom script to show the Statuscake.com tests that are currently down
# uses the jq command line json parser
#


API_KEY="yourapikey"
USERNAME="yourusername"

# get down tests
TESTS=$(curl --silent -H "API: ${API_KEY}" -H "Username: ${USERNAME}" -X GET https://app.statuscake.com/API/Tests/?Status=DOWN)


if [ "$TESTS" == "[]" ]; then
  NROFDOWN=0
else
  # get all test id's, filtered by paused = false as the api can't do that
  TESTIDS=$(echo $TESTS | /usr/local/bin/jq '.[] | select(.Paused == false) | .TestID')
  # count the number of tests, skip empty lines
  NROFDOWN=$(echo "$TESTIDS" | sed '/^\s*$/d' | wc -l | xargs)
fi

if (( $NROFDOWN > 0 )); then
  NAMES=$(echo $TESTS | /usr/local/bin/jq '.[] | select(.Paused == false) | .WebsiteName')
  URLS=$(echo $TESTS | /usr/local/bin/jq '.[] | select(.Paused == false) | .WebsiteURL')
  echo "☝ ${NROFDOWN}⇩|color=#f23400 dropdown=false"
  echo "---";
  echo "$TESTIDS" | while ((i++)); read line
  do
    NAME=$(sed -n ${i}p <<< "$NAMES" | sed "s/\"//g")
    URL=$(sed -n ${i}p <<< "$URLS" | sed "s/\"//g")
    echo "$NAME ($URL) | color=red href=$URL"
  done
else
  echo "☝ 0⇩ |dropdown=false"
  echo "---";
  echo "All up!";
fi
