#! /usr/bin/env python3

import argparse
import os
import subprocess


pde_junit_parent = '.metadata/.plugins/org.eclipse.pde.core/'


def parse_args():
    parser = argparse.ArgumentParser(
            description='''Replace (or create) directory
            .metadata/.plugins/org.eclipse.pde.core/pde-junit/
            in workspace''')

    parser.add_argument('workspace', help='eclipse workspace')
    parser.add_argument('pde_junit', help='your pde-junit/ dir to copy')

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    wsp_pde_junit = os.path.join(args.workspace, pde_junit_parent, 'pde-junit')
    subprocess.check_call(['rm', '-rf', wsp_pde_junit])

    subprocess.check_call(['mkdir', '-p',
        os.path.join(args.workspace, pde_junit_parent)])

    subprocess.check_call(['cp', '-r', args.pde_junit, wsp_pde_junit])
