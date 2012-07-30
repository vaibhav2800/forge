#! /usr/bin/env bash

SCRIPT=`readlink -f "$0"`
DIR=`dirname "$SCRIPT"`

# After closing the browser, chromedriver and the Java process stay hanging
# These can pile up and use a lof of memory if you close & restart the browser
# many times during the day.
# Killing existing chromedriver processes at the start of this script
# will also let the old Java processes connected to them finish.
killall chromedriver

ant -f "$DIR/build.xml" \
	-Ddatadir=/home/someuser/.config/chromium-gmail \
	-Dusername=myusername \
	-Dpasswd_store=gnome \
	run
