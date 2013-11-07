#!/bin/bash

# Absolute path to this script
SCRIPT=`readlink -f $0`

# Absolute path this script is in
DIR=`dirname $SCRIPT`

cd $DIR
java -jar dist/sitecheck.jar
