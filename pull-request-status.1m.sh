#!/bin/bash

#DYNAMIC
user="my@example.com"
token="mytoken"

# STATIC
icon="iVBORw0KGgoAAAANSUhEUgAAABQAAAAWCAYAAADAQbwGAAAAAXNSR0IArs4c6QAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAAAsTAAALEwEAmpwYAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgpMwidZAAACK0lEQVQ4EbWUO2tUQRSAb2K0CMgGsVCUoCCBlCIqNlY+QImPxsLaH5AiIhYWQsDSQgSxsRHUwsJGLYRNFbXRgGDtgqKCqEl8Jz6+b3bO3SFeDRYe+PY85txzZs7euVXVkxU9M1nh9+f4AHprtvuyXlYNk7Ef1uRMi4Rcw7iUHePSWDh2cIaEj9CBOTgOIRcxfsK5CBQ6TlKEqmo3ng8czNEJ9CdYBxfAtR/wAqZhCk7DKlB+KzpJsJ2Wej8zmA/BYgvwPdv6wX3s1aDESZMzxu9nGE1eVR1Bf4AdcAui6Dy2I/kC7tj4DVDqgjHYKwSd3R34Bh5J8Ti3wYfPg7IdnoExc2Mj6ehRucXCu5z0GK2Us3mEfzlFuz/+4xaUvd1QNVC+FoMEPfYQODOLOTdzFmEPOIImsWiS2J2OwfDVzkixmMXfwl1YCX+Ucod1F7JL2xm702gWjRqLRlLj4pKghf5azPx/KbikfrP7Xws6+Jidc1uuWby/brV+vcqHZl3JElct/FLHM971kHg2NYmEk6y6Qz8A6kOg1N0Lewv2K3gD5sb1w+zKLpSvxuHsn0LbdW32bVoe0VtzM8dG0N6wcahlEmuq9rpGB3U0x3xf4yQbsN/DxrymOgttjUjy7u6ETaDsg/XwVAfxWKK8BD/EJ3SyHEPPhBP6OoafLDt5fLsq0VQ75ulovsIDeA5PoAVpLn3o6H4AexvcAz+eTWIDb8xmcGev4Sp45/t/AVL9dQ7qDO64AAAAAElFTkSuQmCC"
url="https://bitbucket.maxxton.com/rest"
auth="Authorization:Bearer ${token}"

export PATH="/usr/local/bin:/usr/bin:$PATH"

declare rowsMine=()
declare countMine=0
declare rowsReview=()
declare countReview=0
declare rowsOther=()
declare countOther=0
declare successfulTotal=0
declare inProgressTotal=0
declare failedTotal=0
declare conflictedTotal=0
declare total=0

_jq() {
  json=$(echo ${1} | base64 --decode)
  echo $json | jq -r ${2}
}

# colors
NORMAL="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
ORANGE="\033[33m"
GRAY="\033[37m"

pullrequests=$(curl -s -H "$auth" "${url}/api/1.0/dashboard/pull-requests?state=OPEN&limit=1000" | jq .values)
#echo $pullrequests
pullrequestsParsed=$(echo "${pullrequests}" | jq -r '.[] | @base64')

# collect all build statuses at once
commitHashes="["
for pullrequest in $pullrequestsParsed; do
  commit=$(_jq $pullrequest '.fromRef.latestCommit')
  commitHashes="${commitHashes} \"$commit\","
done;
commitHashes="${commitHashes%?} ]"
commitStatuses=$(curl -s -d "$commitHashes" -H "Content-Type: application/json" -H "$auth" -X POST "${url}/build-status/1.0/commits/stats")
commitStatusesParsed=$(echo "${commitStatuses}" | jq -r '. | @base64')

for pullrequest in $pullrequestsParsed; do
  title=$(_jq $pullrequest '.title')
  prUrl=$(_jq $pullrequest '.links.self[0].href')
  userObject=$(echo "${pullrequest}" | base64 --decode | jq -r '.author.user | @base64')
  author=$(_jq $userObject '.emailAddress')
  authorName=$(_jq $userObject '.displayName')
  project=$(_jq $pullrequest '.fromRef.repository.project.key')
  toBranch=$(_jq $pullrequest '.toRef.displayId')

  # CLEAN, CONFLICTED
  properties=$(echo "${pullrequest}" | base64 --decode | jq -r '.properties | @base64')
  mergeResult=$(_jq $properties '.mergeResult.outcome')
  openTaskCount=$(_jq $properties '.openTaskCount')
  resolvedTaskCount=$(_jq $properties '.resolvedTaskCount')

  reviewers=$(echo "$(_jq $pullrequest '.reviewers')" | jq -r '.[] | @base64')
  catched=false

  # build status
  commit=$(_jq $pullrequest '.fromRef.latestCommit')
  noBuild=false
  buildStatus=$(_jq $commitStatusesParsed '.["'$commit'"]')

  if [[ $buildStatus == "null" ]]; then
    noBuild=true
  fi
  successful=$(echo "$buildStatus" | jq .successful)
  inProgress=$(echo "$buildStatus" | jq .inProgress)
  inProgressTotal=$(($inProgressTotal+$inProgress))
  failed=$(echo "$buildStatus" | jq .failed)
  failedTotal=$(($failedTotal+$failed))
  buildIcon="✔"
  if (( successful > 0 )); then
    buildIcon="${GREEN}✔${NORMAL}"
  elif (( inProgress > 0 )); then
    buildIcon="${BLUE}↻${NORMAL}"
  elif (( failed > 0 )); then
    buildIcon="${RED}✖${NORMAL}"
  fi

  # reviewers
  unapproved=0
  approved=0
  needsWork=0
  for reviewer in $reviewers; do
    status=$(_jq $reviewer '.status')
    if [ "$status" == "UNAPPROVED" ]; then
      unapproved=$(($unapproved + 1))
    elif [ "$status" == "NEEDS_WORK" ]; then
      needsWork=$(($needsWork + 1))
    elif [ "$status" == "APPROVED" ]; then
      approved=$(($approved + 1))
    fi
  done;
  allReviewers=$(($unapproved + $approved + $needsWork))

  revStatus=$(printf "%-6s" "$approved/$needsWork/$allReviewers")
  if (( needsWork == 0 && approved > 0 && openTaskCount == 0 && failed == 0 && inProgress == 0 )) && (( successful > 0 || noBuild == "true" )); then
    # mergeable
    if (( noBuild == "true" )); then
      # just to add the non building pr's in the total too
      successfulTotal=$(($successfulTotal+1))
    else
      successfulTotal=$(($successfulTotal+$successful))
    fi
    revStatus="${GREEN}$revStatus${NORMAL}"
  fi

  if (( openTaskCount > 0 )); then
    openTaskCount=$(printf "%-2s" $openTaskCount)
    openTaskCount="${ORANGE}${openTaskCount}${NORMAL}"
  else
    openTaskCount=$(printf "%-2s" $openTaskCount)
  fi

  conflicted=""
  if [ "$mergeResult" == "CONFLICTED" ]; then
    if [ "$author" == "$user" ]; then
      conflictedTotal=$(($conflictedTotal + 1))
    fi
    conflicted="🔥 "
  fi

  project=$(printf "%-4s" $project)
  text="B:$buildIcon R:$revStatus T:$openTaskCount $project / ${conflicted}$title (${GRAY}${authorName}${NORMAL}) ➟ ${toBranch} | href=$prUrl font='Andale Mono' length=150 ansi=true"

  # my pr's
  if [ "$author" == "$user" ]; then
    catched=true
    rowsMine[countMine]=$text
    countMine=$(($countMine + 1))
  else
    # pr's that I'm watching and not approved yet
    for reviewer in $reviewers; do
      email=$(_jq $reviewer '.user.emailAddress')
      if [ "$email" == "$user" ]; then
        status=$(_jq $reviewer '.status')
        if [ "$status" == "UNAPPROVED" ]; then
          catched=true
          total=$(($total + 1))

          rowsReview[countReview]=$text
          countReview=$(($countReview + 1))
        fi
      fi
    done;

    # the remaining open pr's
    if (( catched == "false" )); then
      rowsOther[countOther]=$text
      countOther=$(($countOther + 1))
    fi
  fi
done;

declare output
if (( successfulTotal > 0 )); then
  output="✔${successfulTotal}"
fi

if (( inProgressTotal > 0 )); then
  output="${output} ↻${inProgressTotal}"
fi

if (( failedTotal > 0 )); then
  output="${output} ✘${failedTotal}"
fi

if (( conflictedTotal > 0 )); then
  output="${output} 🔥${conflictedTotal}"
fi

if (( total > 0 )); then
  output="${output} ✸ ${total}"
fi


if [ -n "$output" ]; then
  echo "${output} | templateImage=$icon dropdown=false"
  echo ---
  echo "Go to Bitbucket dashboard | href=https://bitbucket.maxxton.com/dashboard"
  echo "Refresh below list | refresh=true"
  if (( countMine > 0 )); then
    echo ---
    echo 👨‍🔧 My Pull Requests
    for row in "${rowsMine[@]}"; do
      echo -e "$row";
    done;
  fi
  if (( countReview > 0 )); then
    echo ---
    echo 👮 Reviewing
    for row in "${rowsReview[@]}"; do
      echo -e "$row";
    done;
  fi
  if (( countOther > 0 )); then
    echo ---
    echo 💉 All remaining Pull Requests
    for row in "${rowsOther[@]}"; do
      echo -e "$row";
    done;
  fi
fi
