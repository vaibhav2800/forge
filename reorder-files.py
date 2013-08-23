#! /usr/bin/env python3

import argparse
import os.path
import random
import shutil
import sys


def parse_args():
    parser = argparse.ArgumentParser(
            description='Prepend/Replace [number] to filenames ' +
            'and *move* the files to the current directory')
    parser.add_argument('file', nargs='+')
    parser.add_argument('-s', '--start-str', default='[', metavar='C',
            help='String before prepended number, default %(default)s.')
    parser.add_argument('-e', '--end-str', default=']', metavar='C',
            help='String after prepended number, default %(default)s.')

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
        dest_files.append(
                args.start_str +
                pad_to_length(str(i+1), max_length) +
                args.end_str +
                strip_prefix(src_files[i], args.start_str, args.end_str))

    for f in dest_files:
        if os.path.exists(f):
            print('Destination file', "‘" + f + "’", 'exists, aborting.',
                    file=sys.stderr)
            sys.exit(1)

    for src, dest in zip(src_files, dest_files):
        shutil.move(src, dest)
