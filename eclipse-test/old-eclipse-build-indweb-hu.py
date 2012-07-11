#! /usr/bin/env python3

import argparse
import subprocess


def parse_args():
    parser = argparse.ArgumentParser(description='''build eclipse workspace
            using http://eclipse.indweb.hu/''')

    parser.add_argument('eclipse_bin', help='eclipse binary')
    parser.add_argument('workspace', help='eclipse workspace')

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    # this doesn't find new classes checked out from CVS
    '''
    subprocess.check_call([args.eclipse_bin, '-noSplash',
        '-data', args.workspace,
        '-application', 'org.eclipse.jdt.apt.core.aptBuild'])
    '''

    # the 'import' command below refreshes the workspace and finds new files
    subprocess.check_call([args.eclipse_bin, '-noSplash',
        '-data', args.workspace,
        '-application', 'com.ind.eclipse.headlessworkspace.Application',
        'import', 'clean', 'build'])
