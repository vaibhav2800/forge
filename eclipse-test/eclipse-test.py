#! /usr/bin/env python3

import argparse
from collections import deque
from collections import OrderedDict
import datetime
import json
import os
import random
import socket
import subprocess
import sys
import time
import traceback


base_port = 50000
program_dir = os.path.dirname(sys.argv[0])
SINGLE_INSTANCE_PORT = 18000
startTime = time.time()


def singleinstance(port):
    '''Provides mutual exclusion by binding a socket. Returns success.

    Not destined for multithreaded use from the same process, but to be called
    once by each process to ensure it is the only instance running.
    '''

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.bind(('localhost', port))

        # prevent a successfully bound socket from being garbage collected,
        # otherwise a second process might be able to bind to the same port
        # while we are still running
        global __bound_sock
        __bound_sock = sock

        return True
    except socket.error:
        return False


sample_modules_info = OrderedDict((
    ('com.company.prj1', ':ext:user@host:path'),
    ('com.company.prj2', ':ext:user@host:path'),
    ))

sample_launchers_info = OrderedDict((
        ('my-suite', OrderedDict((
            ('bin', 'path/to/launcher_binary'),
            ('timeout', 60),
            ))),
        ('another-suite', OrderedDict((
            ('bin', 'path/to/bin2'),
            ('timeout', 600)
            ))),
        ))


def parse_args():
    parser = argparse.ArgumentParser(description='Eclipse Test runner')

    parser.add_argument('eclipse_bin', help='(path to) eclipse binary')
    parser.add_argument('workspace', help='(path to) eclipse workspace')
    parser.add_argument('modules_file',
            help='''
            JSON file containing the list of projects (CVS modules) and their
            corresponding CVSROOTs in the following format: ''' +
            json.dumps(sample_modules_info) + '.')
    parser.add_argument('results_dir',
            help='''
            directory where to put resulting XML files,
            will be created (including parent dirs) if it doesn't exist.
            ''')

    parser.add_argument('--launchers-file', required=True,
            help='''
            JSON file containing the launchers in the format: ''' +
            json.dumps(sample_launchers_info) + '''.
            The 'bin' field points to the executable file starting each suite,
            'timeout' is the number of seconds to let each launcher run
            before killing it.
            The executable will have the following variables added to its
            environment:
            ECLTEST_ECLIPSE_BIN (the eclipse_bin arg above),
            ECLTEST_WSP (the workspace arg above),
            ECLTEST_PORT (the port where the JUnit listener will listen).
            The 'name' field is used for the XML file
            holding the JUnit results in the results_dir.
            ''')
    parser.add_argument('--branch', default='HEAD',
            help='CVS tag/branch to checkout, default %(default)s')
    parser.add_argument('--no-checkout', action='store_true',
            help="Don't checkout from CVS, use existing code in workspace")
    parser.add_argument('--no-build', action='store_true',
            help='''Skip building workspace with a headless eclipse.
            Should only use this together with --no-checkout.''')
    parser.add_argument('--parallel', type=int, metavar='N',
            help='Run %(metavar)s launchers in parallel.')
    parser.add_argument('--random', action='store_true',
            help='Run launchers in random order')
    parser.add_argument('--run-after-checkout', metavar='COMMAND',
            help='Run %(metavar)s after checkout, before build')
    parser.add_argument('--print-args', action='store_true',
            help='''Print the arguments this program was invoked with
            to the ECLTEST_RESULT file. Can be used for debugging.''')

    return parser.parse_args()


def launch(args, launcher_name, launcher_data, port):
    'Starts launcher and the junit test listener, returns the Popen objects.'

    # running 'java -jar' instead of the .py helper so 'kill()' will stop
    # the java process and free up the port it's listening on.

    # need abspath because we're changing crt dir (cwd=...)
    p1 = subprocess.Popen(['java', '-jar',
        os.path.abspath(
            os.path.join(program_dir, 'eclipse-junit-listener',
                'dist', 'eclipse-junit-listener.jar')),
        launcher_name, str(port)],
        cwd=args.results_dir)

    env = dict(os.environ)
    env['ECLTEST_ECLIPSE_BIN'] = args.eclipse_bin
    env['ECLTEST_WSP'] = args.workspace
    env['ECLTEST_PORT'] = str(port)
    p2 = subprocess.Popen([launcher_data['bin']], env=env)

    return p1, p2


def run_suites_in_parallel(args, launchers_info):
    # don't modify the original dictionary
    pending_launchers = OrderedDict(launchers_info)

    killed_suites = set()
    running = {}
    port = base_port

    if not args.parallel or args.parallel < 1:
        args.parallel = 1

    while pending_launchers or running:
        while pending_launchers and len(running) < args.parallel:
            # popitem(False) to get first (not last) item from OrderedDict
            name, data = pending_launchers.popitem(False)
            port += 1
            p1, p2 = launch(args, name, data, port)
            running[name] = (p1, p2, time.time() + data['timeout'])

        to_remove = []
        while running and not to_remove:
            time.sleep(1)
            for name, (p1, p2, endTime) in running.items():
                if p1.poll() is None or p2.poll() is None:
                    if time.time() > endTime:
                        # remove on next pass
                        killed_suites.add(name)
                        if p1.poll() is None:
                            p1.kill()
                        if p2.poll() is None:
                            p2.kill()
                else:
                    to_remove.append(name)

        for name in to_remove:
            running.pop(name)

    return killed_suites


def run_suites_sequentially(args, launchers_info):
    killed_suites = set()
    port = base_port
    for launcher_name, launcher_data in launchers_info.items():
        port += 1
        p1, p2 = launch(args, launcher_name, launcher_data, port)

        endTime = time.time() + launcher_data['timeout']
        while p1.poll() is None or p2.poll() is None:
            if time.time() < endTime:
                time.sleep(1)
            else:
                killed_suites.add(launcher_name)
                if p1.poll() is None:
                    p1.kill()
                if p2.poll() is None:
                    p2.kill()

    return killed_suites


def printRunTime(f):
    endTime = time.time()
    print('Run time', datetime.timedelta(seconds=int(endTime-startTime)),
            'from',
            time.strftime("%Y.%m.%d-%H:%M:%S", time.localtime(startTime)),
            'to',
            time.strftime("%Y.%m.%d-%H:%M:%S", time.localtime(endTime)),
            file=f)


def printArgsIfRequested(f, args):
    if args.print_args:
        print(args, file=f)


def humansize(n, sizes, beforeUnit='', sep=' ',
        noLeadZero=True, noTrailZero=True):
    '''humansize(n, sizes, beforeUnit='', sep=' ',
    noLeadZero=True, noTrailZero=True) -> str

    sizes = OrderedDict((('s', 1), ('m', 60), ('h', 60)))
    Can omit leading and trailing units that are zero.
    Returns: 1h 5m 20s
    sep - between 1h and 5m
    beforeUnit - before '1' and 'h'
    '''

    d = deque()
    for unit, size in sizes.items():
        if len(d):
            prev_unit, x = d.popleft()
            d.appendleft((prev_unit, x % size))
        else:
            x = n
        d.appendleft((unit, x // size))

    if noLeadZero:
        while len(d):
            unit, size = d.popleft()
            if size:
                d.appendleft((unit, size))
                break

    if noTrailZero:
        while len(d):
            unit, size = d.pop()
            if size:
                d.append((unit, size))
                break

    if not d:
        return '0'

    return sep.join([str(size) + beforeUnit + unit for unit, size in d])


def printKilledSuites(f, killed_suites, launchers_info):
    '''Prints a status line (other than 'OK\n') and lists the killed suites.

    Args: f - file, killed_suites - set(suite_name), launchers_info.
    '''

    print('The following test suites TIMED OUT:', file=f)
    for s in killed_suites:
        if s in launchers_info:
            timeout = humansize(
                    launchers_info[s]['timeout'],
                    OrderedDict((('s', 1), ('m', 60), ('h', 60))))
        else:
            timeout = 'timeout not found'
        print(s, timeout, sep=': ', file=f)


if __name__ == '__main__':
    args = parse_args()
    if not singleinstance(SINGLE_INSTANCE_PORT):
        print('Another instance is currently running', file=sys.stderr)
        sys.exit(1)
    os.makedirs(args.results_dir, exist_ok = False)
    killed_suites = set()

    try:
        if not args.no_checkout:
            subprocess.check_call([
                os.path.join(program_dir, 'cvs-checkout.py'),
                args.workspace, args.modules_file,
                '--branch', args.branch])

        if args.run_after_checkout:
            subprocess.check_call([args.run_after_checkout])

        if not args.no_build:
            subprocess.check_call([
                os.path.join(program_dir, 'eclipse-build.py'),
                args.eclipse_bin, args.workspace])

        subprocess.check_call(['ant', '-f',
            os.path.join(program_dir, 'eclipse-junit-listener', 'build.xml'),
            'jar'])

        with open(args.launchers_file, encoding='utf-8') as f:
            launchers_info = json.load(f, object_pairs_hook=OrderedDict)

        if args.random:
            shuffled_launchers = list(launchers_info.items())
            random.shuffle(shuffled_launchers)
            launchers_info = OrderedDict(shuffled_launchers)

        port = 50000
        if args.parallel:
            killed_suites = run_suites_in_parallel(args, launchers_info)
        else:
            killed_suites = run_suites_sequentially(args, launchers_info)
    except:
        with open(os.path.join(args.results_dir, 'ECLTEST_RESULT'),
                encoding='utf-8', mode='w') as f:
            print('CRASHED', file=f)
            printRunTime(f)
            printArgsIfRequested(f, args)
            traceback.print_exc(file=f)
    else:
        with open(os.path.join(args.results_dir, 'ECLTEST_RESULT'),
                encoding='utf-8', mode='w') as f:
            if killed_suites:
                printKilledSuites(f, killed_suites, launchers_info)
            else:
                print('OK', file=f)
            printRunTime(f)
            printArgsIfRequested(f, args)
