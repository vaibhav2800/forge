#! /usr/bin/env python3

import argparse
from collections import OrderedDict
import json
import os
import subprocess


sample_modules_info = OrderedDict((
    ('com.company.prj1', ':ext:user@host:path'),
    ('com.company.prj2', ':ext:user@host:path'),
    ))


def parse_args():
    parser = argparse.ArgumentParser(
            description='Replace CVS modules with latest from HEAD')

    parser.add_argument('dir', help='containing directory')
    parser.add_argument('modules_file',
            help='''
            JSON file containing the list of projects (CVS modules) and their
            corresponding CVSROOTs in the following format: ''' +
            json.dumps(sample_modules_info) + '.')
    parser.add_argument('--branch', default='HEAD',
            help='''CVS tag/branch to checkout, default %(default)s''')

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    with open(args.modules_file, encoding='utf-8') as f:
        modules_info = json.load(f, object_pairs_hook=OrderedDict)

    os.chdir(args.dir)
    for (module, cvsroot) in modules_info.items():
        subprocess.check_call(
                ['cvs', '-d', cvsroot, 'checkout', '-r', args.branch, module])
