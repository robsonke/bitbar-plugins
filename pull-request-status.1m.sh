#!/bin/bash

#DYNAMIC
user="my@example.com"
token="mytoken"

# STATIC
icon="iVBORw0KGgoAAAANSUhEUgAAABQAAAAWCAYAAADAQbwGAAAAAXNSR0IArs4c6QAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAAAsTAAALEwEAmpwYAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgpMwidZAAACK0lEQVQ4EbWUO2tUQRSAb2K0CMgGsVCUoCCBlCIqNlY+QImPxsLaH5AiIhYWQsDSQgSxsRHUwsJGLYRNFbXRgGDtgqKCqEl8Jz6+b3bO3SFeDRYe+PY85txzZs7euVXVkxU9M1nh9+f4AHprtvuyXlYNk7Ef1uRMi4Rcw7iUHePSWDh2cIaEj9CBOTgOIRcxfsK5CBQ6TlKEqmo3ng8czNEJ9CdYBxfAtR/wAqZhCk7DKlB+KzpJsJ2Wej8zmA/BYgvwPdv6wX3s1aDESZMzxu9nGE1eVR1Bf4AdcAui6Dy2I/kC7tj4DVDqgjHYKwSd3R34Bh5J8Ti3wYfPg7IdnoExc2Mj6ehRucXCu5z0GK2Us3mEfzlFuz/+4xaUvd1QNVC+FoMEPfYQODOLOTdzFmEPOIImsWiS2J2OwfDVzkixmMXfwl1YCX+Ucod1F7JL2xm702gWjRqLRlLj4pKghf5azPx/KbikfrP7Xws6+Jidc1uuWby/brV+vcqHZl3JElct/FLHM971kHg2NYmEk6y6Qz8A6kOg1N0Lewv2K3gD5sb1w+zKLpSvxuHsn0LbdW32bVoe0VtzM8dG0N6wcahlEmuq9rpGB3U0x3xf4yQbsN/DxrymOgttjUjy7u6ETaDsg/XwVAfxWKK8BD/EJ3SyHEPPhBP6OoafLDt5fLsq0VQ75ulovsIDeA5PoAVpLn3o6H4AexvcAz+eTWIDb8xmcGev4Sp45/t/AVL9dQ7qDO64AAAAAElFTkSuQmCC"
url="https://bitbucket.example.com/rest"
auth="Authorization:Bearer ${token}"

export PATH="/usr/local/bin:/usr/bin:$PATH"

declare rows=()
declare count=0
declare successful=0
declare inProgress=0
declare failed=0
declare conflicted=0
declare total=0

_jq() {
    echo ${1} | base64 --decode | jq -r ${2}
}

pullrequests=$(curl -s -H "$auth" "${url}/api/1.0/dashboard/pull-requests?state=OPEN&limit=1000" | jq .values)
for pullrequest in $(echo "${pullrequests}" | jq -r '.[] | @base64'); do

  title=$(_jq $pullrequest '.title')
  prUrl=$(_jq $pullrequest '.links.self[0].href')
  author=$(_jq $pullrequest '.author.user.emailAddress')
  if [ "$author" == "$user" ]; then
    commit=$(_jq $pullrequest '.fromRef.latestCommit')
    status=$(curl -s -H "$auth" "${url}/build-status/1.0/commits/stats/$commit")
    successful=$(($successful+$(echo "$status" | jq .successful)))
    inProgress=$(($inProgress+$(echo "$status" | jq .inProgress)))
    failed=$(($failed+$(echo "$status" | jq .failed)))

    rows[count]="👨‍🔧 - $title | href=$prUrl"
    count=$(($count + 1))

    conflicted=$(_jq $pullrequest '.properties.mergeResult.outcome')
    if [ "$conflicted" == "CONFLICTED" ]; then
      conflicted=$(($conflicted + 1))
    fi 
  fi

  for reviewer in $(echo "$(_jq $pullrequest '.reviewers')" | jq -r '.[] | @base64'); do
    email=$(_jq $reviewer '.user.emailAddress')
    if [ "$email" == "$user" ]; then
      status=$(_jq $reviewer '.status')
      if [ "$status" == "UNAPPROVED" ]; then
        total=$(($total + 1))

        rows[count]="👮🏻$title | href=$prUrl"
        count=$(($count + 1))
      fi
    fi
  done;
done;

declare output
if (( successful > 0 )); then
  output="✔${successful}"
fi

if (( inProgress > 0 )); then
  if [ -n "$output" ]; then
    output="${output} ↻${inProgress}"
  else
    output="↻${inProgress}"
  fi
fi

if (( failed > 0 )); then
  if [ -n "$output" ]; then
    output="${output} ✘${failed}"
  else
    output="✘${failed}"
  fi
fi

if (( conflicted > 0 )); then
  if [ -n "$output" ]; then
    output="${output} - 🔥${conflicted}"
  else
    output="${output} 🔥${conflicted}"
  fi
fi

if (( total > 0 )); then
  if [ -n "$output" ]; then
    output="${output} - 👮🏻${total}"
  else
    output="${output} 👮🏻${total}"
  fi
fi

if [ -z "$output" ]; then
  output="👌"
fi

echo "${output} | templateImage=$icon dropdown=false"
echo ---
if (( count > 0 )); then
  for row in "${rows[@]}"; do
    echo "$row";
  done;
fi
echo "Go to dashboard | href=https://bitbucket.example.com/dashboard"