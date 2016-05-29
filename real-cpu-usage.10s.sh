#!/bin/bash

# Real CPU Usage
# BitBar plugin
#
# by Mat Ryer and Tyler Bunnell
# but heavily modified by myself to fit my needs.
# Calcualtes and displays real CPU usage stats.

ps -A -o %cpu | awk '{s+=$1} END {print "cpu:" s "%"}'

echo "---"
ps aux | sort -nrk 3,3 | head -n 5