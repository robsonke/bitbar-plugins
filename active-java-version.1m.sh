#!/bin/bash

# Active Java version
# BitBar plugin
#
# by Rob Sonke
#
# Grabs java version from the command line by trying the path first, then JAVA_HOME

VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
if [ -z "$VERSION" ]; then
  VERSION=$($JAVA_HOME/bin/java -version 2>&1 | awk -F '"' '/version/ {print $2}')
fi

echo -n "♨︎: "
echo $VERSION


