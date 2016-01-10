#!/bin/bash

# Vpn uptime
#
# by NBittmann
#
# Simply checks the uptime of your VPN connection and shows it in bitbar

# Adjust settings to match your environment.
# change iface to your VPN interface you can find this via ifconfig in your terminal
#
# Change ServiceName to your VPN name as it states in OS X settings


iface="ppp0"

ServiceName=("Maxxton")

# Do not touch things below this


if [ "$1" = 'connect' ]; then
  osascript -e 'tell application "System Events"
        tell current location of network preferences
            set VPN to service "'"${ServiceName}"'"
            if exists VPN then connect VPN
      end tell
    end tell'
  exit
fi

if [ "$1" = 'disconnect' ]; then
    osascript -e 'tell application "System Events"
          tell current location of network preferences
              set VPN to service "'"${ServiceName}"'"
              if exists VPN then disconnect VPN
        end tell
      end tell'
  exit
fi

if [[ `ifconfig | grep $iface` ]]; then
	converttime() {
	 ((h=${1}/3600))
	 ((m=(${1}%3600)/60))
	 ((s=${1}%60))
	 printf "%02d:%02d:%02d\n" $h $m $s
	}
	age=`echo $(($(date +%s) - $(stat -t %s -f %m -- "/var/run/$iface.pid")))`

	echo "vpn: $(converttime $age)"
	echo "---"
	echo "Disconnect connection | color=red bash=$0 param1=disconnect terminal=false"
	echo "(External IP address) | color=white"  
	dig +tries=1 +short myip.opendns.com @resolver1.opendns.com	
	echo "(Internal IP address) | color=white" 
	ifconfig ppp0 | tr -d '\n'  | awk -F " "  '{print $6}'
else
	# placeholder to minimize movement in menubar when inactive will add a minial space between two icons
	echo "|color=transparent"
	
fi




