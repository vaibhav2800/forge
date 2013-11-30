#! /usr/bin/env python3

import argparse
from collections import OrderedDict
import html
import os
import string
import textwrap
import urllib.parse


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
def getHtmlStart(title):
    return html_start_templ.substitute({'title': html.escape(title)})

html_end = textwrap.dedent('''\
        </body>
        </html>
        ''')

dir_templ = string.Template(textwrap.dedent('''\
        <a href="$nameHref/">$nameText/</a> $size<br>
        '''))

file_templ = string.Template(textwrap.dedent('''\
        <a href="$nameHref">$nameText</a> $size<br>
        '''))

def getLinkHtml(whichTempl, name, size):
    return whichTempl.substitute({
        'nameHref': urllib.parse.quote(name),
        'nameText': html.escape(name),
        'size': html.escape(human_size(size))
        })

def getDirHtml(name, size):
    return getLinkHtml(dir_templ, name, size)

def getFileHtml(name, size):
    return getLinkHtml(file_templ, name, size)


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
        f.write(getHtmlStart(title))
        for name in names:
            path = os.path.join(root, name)
            if os.path.isdir(path):
                size = process_tree(path, name)
                htmlGetter = getDirHtml
            else:
                size = os.path.getsize(path)
                htmlGetter = getFileHtml
            f.write(htmlGetter(name, size))
            total_size += size
        f.write(html_end)

    return total_size


if __name__ == '__main__':
    global args
    args = parse_args()
    process_tree(args.dir, '/')
