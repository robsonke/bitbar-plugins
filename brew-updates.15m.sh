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

# brew
UPDATES=$(/usr/local/bin/brew outdated --verbose);
UPDATE_COUNT=$(echo "$UPDATES" | grep -c '[^[:space:]]');

# brew cask
for c in $(/usr/local/bin/brew cask list); do
  # brew cask info is slow but much more reliable then 'brew cask outdated'
  CASK_INFO=$(/usr/local/bin/brew cask info $c)
  CASK_NAME=$(echo "$c" | cut -d ":" -f1 | xargs)
  NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | sed 's/ *//' | cut -d " " -f1)
  IS_CURRENT_VERSION_INSTALLED=$(echo "$CASK_INFO" | grep -q ".*/Caskroom/$CASK_NAME/$NEW_VERSION.*" 2>&1 && echo true )

  if [[ -z "$IS_CURRENT_VERSION_INSTALLED" ]]; then
    if [ -n "$UPDATES_CASK" ]; then
      UPDATES_CASK="$UPDATES_CASK"$'\n'"$CASK_NAME ($NEW_VERSION)"
    else
      UPDATES_CASK="$CASK_NAME ($NEW_VERSION)"
    fi
  fi

  CASK_INFO=""
  NEW_VERSION=""
  IS_CURRENT_VERSION_INSTALLED=""
done

UPDATE_CASK_COUNT=$(echo "$UPDATES_CASK" | grep -c '[^[:space:]]');

# and output
if (( $UPDATE_COUNT > 0 )) || (( $UPDATE_CASK_COUNT > 0 )); then
  echo "♺ $UPDATE_COUNT / $UPDATE_CASK_COUNT | dropdown=false"
  if [ -n "$UPDATES" ]; then
    echo "---";
    echo "Upgrade all brew | bash='$SCRIPT' param1=launch-iterm param2=brew_upgrade terminal=false"
    echo "---";
    echo "$UPDATES" | awk '{print $0 " | bash='$SCRIPT' param1=launch-iterm param2=/usr/local/bin/brew param3=upgrade param4="$1" terminal=false" }'
  fi
  if [ -n "$UPDATES_CASK" ]; then
    echo "---";
    echo "Upgrade all brew casks | bash='$SCRIPT' param1=launch-iterm param2=brew_cask_upgrade terminal=false"
    echo "---";
    echo "$UPDATES_CASK" | awk '{print $0 " | bash='$SCRIPT' param1=launch-iterm param2=\"/usr/local/bin/brew cask install --force\" param3="$1" terminal=false" }'
  fi
fi


