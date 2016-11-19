#!/usr/bin/env bash

#
# Timezones
#
# Display times in other timezones
#
# Dependencies:
# brew install node
# npm install moment
# npm install moment-timezone
#

export PATH=${PATH}:/usr/local/bin
# Nodejs version manager
export NVM_DIR="$HOME/.nvm"
source $(brew --prefix nvm)/nvm.sh

getTime() {
  TZ="$2"
  MOMT="`dirname $0`/node_modules/moment-timezone"

  RES=`echo "var m=require('${MOMT}'); console.log(m().tz('$2').format('h:mm A'))" | node`
  if [ ! -z "$3" ]; then
    echo "$1" "$RES" "| font='Inconsolata LGC'"
  else
    echo "$RES"
  fi
}

getTime "Pune:" "Asia/Kolkata" 1
echo "---"
getTime "Goes:" "Europe/Amsterdam" 1
echo "---"
getTime "DC:" "America/New_York" 1
