#! /usr/bin/env python3

import argparse
import os.path
import random
import shutil
import sys


# This program raises an interesting math question:
# If we take a tuple of N items and shuffle them (with each permutation having
# equal probability) what is the probability that all items have changed
# position (or alternatively that some items haven't)?
#
# A permutation is ‘good’ if item ‘i’ is not in position ‘i’ (i.e. all items
# have changed position). G(n) is the number of good permutations of n items.
# There is at least 1 good permutation for n > 1, e.g. (n, n-1, … 2, 1).
# Let this be a good permutation of n items:
#  1 2 … k … n
# ┌─┬─┬─┬─┬─┬─┐
# │ │ │ │n│ │x│
# └─┴─┴─┴─┴─┴─┘
# Item n is in slot k ≠ n, slot n holds item x ≠ n. Let's swap slots k and n:
#  1 2 … k … n
# ┌─┬─┬─┬─┬─┬─┐
# │ │ │ │x│ │n│
# └─┴─┴─┴─┴─┴─┘
# If x≠k, slots 1…n-1 form a good permutation of n-1 items.
# If x=k, slots 1…k-1 and k+1…n-1 form a good permutation of n-1 items.
# So a good permutation of n items can be created like this:
# ― choose a k, 1<=k<=n-1.
#   ― Choose a good permutation of n-1 items, and swap slots k and n
#   ― Choose a good permutation of n-2 items, place n on slot k and k on slot n
# G(n) = (n-1) × (G(n-1) + G(n-2))


def parse_args():
    parser = argparse.ArgumentParser(
            description='Prepend/Replace [number] to filenames ' +
            'and *move* the files to the current directory')
    parser.add_argument('file', nargs='+')
    parser.add_argument('-s', '--start-str', default='[', metavar='C',
            help='String before prepended number, default %(default)s.')
    parser.add_argument('-e', '--end-str', default=']', metavar='C',
            help='String after prepended number, default %(default)s.')
    parser.add_argument('--strip', action='store_true',
            help='Strip [number] prefixes only.')

    args = parser.parse_args()
    if len(args.start_str) < 1:
        raise ValueError('start-str "' + args.start_str + '" has length ' +
                str(len(args.start_str)))
    if len(args.end_str) < 1:
        raise ValueError('end-str "' + args.end_str + '" has length ' +
                str(len(args.end_str)))
    return args


def pad_to_length(string, n, char='0'):
    if (len(char) != 1):
        raise ValueError('Padding char "' + char + '" has length ' +
                str(len(char)))
    k = len(string)
    if (k < n):
        return (n - k) * char + string
    return string


def strip_prefix(string, start_str, end_str):
    i = string.find(start_str)
    if i == -1:
        return string
    j = string.find(end_str, i+len(start_str))
    if j == -1:
        return string
    return string[j+len(end_str):]


if __name__ == '__main__':
    args = parse_args()
    max_length = len(str(len(args.file)))

    src_files = list(args.file)
    random.shuffle(src_files)
    dest_files = []
    for i in range(len(src_files)):
        if args.strip:
            dest_name = ''
        else:
            dest_name = (args.start_str +
                    pad_to_length(str(i+1), max_length) +
                    args.end_str)
        dest_name += strip_prefix(src_files[i], args.start_str, args.end_str)
        dest_files.append(dest_name)

    for f in dest_files:
        if os.path.exists(f):
            print('Destination file', "‘" + f + "’", 'exists, aborting.',
                    file=sys.stderr)
            sys.exit(1)

    for src, dest in zip(src_files, dest_files):
        shutil.move(src, dest)
