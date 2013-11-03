#! /usr/bin/env python3

import argparse
from collections import OrderedDict
import os
import string
import textwrap


def parse_args():
    parser = argparse.ArgumentParser(
            description='Create index.html files in dir tree')
    parser.add_argument('dir', help='Root of directory tree to process')
    parser.add_argument('--index-file', default='index.html',
            help='File name to generate, default %(default)s')
    return parser.parse_args()


html_start_templ = string.Template(textwrap.dedent('''\
        <!doctype html>
        <head>
            <meta charset="utf-8">
            <title>$title</title>
        </head>
        <body>
        '''))

html_end = textwrap.dedent('''\
        </body>
        </html>
        ''')

dir_templ = string.Template(textwrap.dedent('''\
        <a href="$name/">$name/</a> $size<br>
        '''))

file_templ = string.Template(textwrap.dedent('''\
        <a href="$name">$name</a> $size<br>
        '''))


def human_size(n, units=OrderedDict((
    ('B', 1), ('K', 1024), ('M', 1024), ('G', 1024), ('T', 1024))), sep=''):
    first = True
    for next_unit, mul in units.items():
        if first:
            first = False
            unit = next_unit
            size = mul
            continue
        else:
            next_size = size * mul
            if next_size > n:
                break
            unit = next_unit
            size = next_size

    return str(n // size) + sep + unit


def process_tree(root, title):
    '''Processes the directory tree at ‘root’, using the given HTML title'''

    names = os.listdir(root)
    names.sort()
    total_size = 0

    index_path = os.path.join(root, args.index_file)
    with open(index_path, mode='x', encoding='utf-8') as f:
        f.write(html_start_templ.substitute({'title': title}))
        for name in names:
            path = os.path.join(root, name)
            if os.path.isdir(path):
                size = process_tree(path, name)
                templ = dir_templ
            else:
                size = os.path.getsize(path)
                templ = file_templ
            f.write(templ.substitute({'name': name, 'size': human_size(size)}))
            total_size += size
        f.write(html_end)

    return total_size


if __name__ == '__main__':
    global args
    args = parse_args()
    process_tree(args.dir, '/')
