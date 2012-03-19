#! /usr/bin/env python3

import argparse
import os
import subprocess
import sys


def parse_args():
    parser = argparse.ArgumentParser(
            description='Listen for Eclipse JUnit results')

    parser.add_argument('outdir', help='output directory, must exist')
    parser.add_argument('suite', help='test suite name')
    parser.add_argument('port', help='port to listen on for test results')

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    program_dir_abs = os.path.abspath(os.path.dirname(sys.argv[0]))
    os.chdir(args.outdir)
    subprocess.check_call(['ant',
        '-f',
        os.path.join(program_dir_abs, 'build.xml'),
        '-Dsuite=' + args.suite,
        '-Dport=' + args.port])
