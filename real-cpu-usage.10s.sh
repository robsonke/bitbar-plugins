#!/bin/bash

# Real CPU Usage
# BitBar plugin
#
# by Mat Ryer and Tyler Bunnell
#
# Calcualtes and displays real CPU usage stats.

IDLE=`ps aux | awk {'sum+=$3;print sum'} | tail -n 1`

USED=`echo 100 - $IDLE | bc`

echo -n "cpu: "
echo $USED%
