#! /usr/bin/env python3

import argparse
import os
import subprocess


def parse_args():
    parser = argparse.ArgumentParser(
            description='build eclipse workspace using CDT plugin')

    parser.add_argument('eclipse_bin', help='eclipse binary')
    parser.add_argument('workspace', help='eclipse workspace')

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    command = [args.eclipse_bin, '-noSplash', '--launcher.suppressErrors',
            '-data', args.workspace, '-application',
            'org.eclipse.cdt.managedbuilder.core.headlessbuild']

    for name in os.listdir(args.workspace):
        # filter out .metadata (if it exists), .git, etc.
        if not name.startswith('.'):
            command.extend(['-import', os.path.join(args.workspace, name)])

    command.extend(['-cleanBuild', 'all'])

    subprocess.check_call(command)
