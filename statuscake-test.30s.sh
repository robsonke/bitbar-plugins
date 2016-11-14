#!/bin/bash

#
# Custom script to show the Statuscake.com tests that are currently down
# uses the jq command line json parser
#


API_KEY="fill in your status cake api key"
USERNAME="fill in your status cake user name"

# get down tests
TESTS=$(curl --silent -H "API: ${API_KEY}" -H "Username: ${USERNAME}" -X GET https://app.statuscake.com/API/Tests/?Status=UP)


if [ "$TESTS" == "[]" ]; then
  NROFDOWN=0
else
  TESTIDS=$(echo $TESTS | jq '.[] | .TestID')
  NROFDOWN=$(echo "$TESTIDS" | wc -l | xargs)
fi


if (( $NROFDOWN > 0 )); then
  echo "sc: ${NROFDOWN}⇩|color=#f23400 dropdown=false"
  echo "---";
  echo $TESTIDS | while read line
  do
    # get details of specific test
    DETAILS=$(curl --silent -H "API: ${API_KEY}" -H "Username: ${USERNAME}" -X GET https://app.statuscake.com/API/Tests/Details/?TestID=$line)
    echo $DETAILS | jq '.WebsiteName'
  done
else
  echo "sc: 0⇩|dropdown=false"
  echo "---";
  echo "All up!";
fi







