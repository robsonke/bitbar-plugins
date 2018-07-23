#!/bin/bash

#
# Custom script to show the Statuscake.com tests that are currently down
# uses the jq command line json parser
#


API_KEY="YpAaEOaeRdy4IgO5WxkP"
USERNAME="robsonke"

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
  echo "☝ ${NROFDOWN}⇩|color=#f23400 dropdown=false"
  echo "---";
  echo "$TESTIDS" | while read line
  do
    # get details of specific test
    DETAILS=$(curl --silent -H "API: ${API_KEY}" -H "Username: ${USERNAME}" -X GET https://app.statuscake.com/API/Tests/Details/?TestID=$line)
    NAME=$(echo $DETAILS | /usr/local/bin/jq '.WebsiteName')
    URL=$(echo $DETAILS | /usr/local/bin/jq '.WebsiteHost')
    echo "$NAME | color=red href=$URL"
  done
else
  echo "☝ 0⇩ |dropdown=false"
  echo "---";
  echo "All up!";
fi
