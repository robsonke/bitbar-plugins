#!/bin/bash

####
# List available updates from Homebrew (OS X)
###
exit_with_error() {
  echo "err | color=red";
  exit 1;
}

# when relaunching this script from an action, we open iterm
# workaround till bitbar supports iterm
if [ "$1" = 'launch-iterm' ]; then
  param="$2 $3 $4 $5 $6"
  osascript -e 'tell application "iTerm" to tell current window to set newTab to (create tab with default profile)'
  osascript -e 'tell application "iTerm" to tell current window to tell current tab to tell current session to write text "'"$param"'"'
  exit
fi

/usr/local/bin/brew update > /dev/null || exit_with_error;

SCRIPT=$0

UPDATES=$(/usr/local/bin/brew outdated --verbose);
UPDATE_COUNT=$(echo "$UPDATES" | grep -c '[^[:space:]]');

UPDATES_CASK=$(/usr/local/bin/brew cask outdated --verbose);
UPDATE_CASK_COUNT=$(echo "$UPDATES_CASK" | grep -c '[^[:space:]]');

if (( $UPDATE_COUNT > 0 )) || (( $UPDATE_CASK_COUNT > 0 )); then
  echo "♺ $UPDATE_COUNT / $UPDATE_CASK_COUNT | dropdown=false"
  echo "---";
  if [ -n "$UPDATES" ]; then
    echo "Upgrade all brew | bash='$SCRIPT' param1=launch-iterm param2=brew_upgrade terminal=false"
    echo "$UPDATES" | awk '{print $0 " | bash='$SCRIPT' param1=launch-iterm param2=/usr/local/bin/brew param3=upgrade param4="$1" terminal=false" }'
  fi
  if [ -n "$UPDATES_CASK" ]; then
    echo "---";
    echo "Upgrade all brew casks | bash='$SCRIPT' param1=launch-iterm param2=brew_cask_upgrade terminal=false"
    echo "$UPDATES_CASK" | awk '{print $0 " | bash='$SCRIPT' param1=launch-iterm param2=\"/usr/local/bin/brew cask install --force\" param3="$1" terminal=false" }'
  fi
fi


