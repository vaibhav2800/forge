#!/bin/bash

# Generates raw-txt/ from txt/
# Run this script from the output directory: "rezitests-<timestamp>"
#
# Copies files from txt/ to raw-txt/ (only category files, not 'all.txt')
# - removes first line "indexed on <date>"
# - splits the answers (last line of file) to multiple lines
#
# The resulting files can be used to reflect website changes over time:
# diffing "run-<timestamp1>/raw-txt" and "run-<timestamp2>/raw-txt"
# will show website changes between the two runs.

out_dir="raw-txt"
mkdir $out_dir

for src_file in txt/[0-9]*; do
	dest_file=$out_dir/$(basename $src_file)
	# 2 sed commands:
	# delete first line
	# replace "   " with "\n" on last line
	sed -e '1 d' -e '$ s/   /\n/g' $src_file >$dest_file
done
