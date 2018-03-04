#!/bin/bash

# Current network location
# BitBar plugin
#
# by Rob Sonke
#
# Shows your current network location.

CURRENT_LOCATION=$(networksetup -getcurrentlocation)
echo ⚲ $CURRENT_LOCATION
