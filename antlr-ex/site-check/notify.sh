#!/bin/bash

# apt-get install libnotify-bin for popups
notify-send $1 "$2 -> $3"

echo "$4 $1	$2 -> $3" >> ~/Desktop/items-changed
