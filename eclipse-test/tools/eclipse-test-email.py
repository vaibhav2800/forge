#! /usr/bin/env python3

import argparse
from collections import OrderedDict
import configparser
import email.message
import json
import smtplib
import util.testresults


sample_config = OrderedDict((
    ('server', 'mail.domain.com'),
    ('port', 465),
    ('ssl', True),
    ('user', 'user@domain.com'),
    ('pass', 'pa$$word'),
    ('from', 'email@domain.com'),
    ('to', 'email@domain.com'),
    ('website', 'http://website-url/'),
    ))


def parse_args():
    parser = argparse.ArgumentParser('Send email with test results')
    parser.add_argument('containing_dir',
            help='''
            directory containing the output directories produced by
            eclipse-test.py, one for each test run.
            ''')
    parser.add_argument('--config', required=True,
            help='Email config file. It has the following format: ' +
            json.dumps(sample_config) + '. "website" is optional.')
    parser.add_argument('--latest', required=True,
            help='''
            Auto-generated file containing the latest test run sent by email.
            ''')

    parser.add_argument('--email-on-first-run', action='store_true',
            help='Send email even if latest_file does not exist')

    return parser.parse_args()


def get_last_reported(latest_file):
    '''Returns the name of the latest test run reported, or None.'''
    latest_config = configparser.ConfigParser()
    latest_config.read(args.latest)
    if 'General' not in latest_config:
        latest_config['General'] = {}
    return latest_config['General'].get('last_reported')


def write_last_reported(latest_file, name):
    '''Writes name to file as the last reported.

    May throw exceptions.
    '''

    latest_config = configparser.ConfigParser()
    latest_config['General'] = {'last_reported': name}
    with open(latest_file, 'w', encoding='utf-8') as f:
        latest_config.write(f)


def get_subject(latest_status, latest_suites):
    crashed = not latest_status.startswith('OK\n')
    subj = '[tests]'
    if crashed:
        subj += ' (inconclusive)'

    nBad = sum(s.nErr + s.nFail for s in latest_suites)
    subj += (' ' + str(nBad) + ' FAIL') if nBad else ' PASS'
    return subj


def get_msg_body(latest_status, latest_suites):
    body = ''
    if not latest_status.startswith('OK\n'):
        body += 'Error running tests:\n'
    body += latest_status
    for suite in latest_suites:
        body += '\n\n' + suite.name
        nBad = suite.nErr + suite.nFail
        if not nBad:
            body += ' PASS (' + str(suite.nTests) + ')\n'
        else:
            body += ' ' + str(nBad)+' / '+str(suite.nTests) + ' FAILED:\n\n'
            for t in suite.testcases:
                if t.err or t.fail:
                    body += t.name + '\n'

    return body


def send_email(latest_status, latest_suites, prev_suites, config_file):
    with open(config_file, encoding='utf-8') as f:
        config = json.load(f)

    msg = email.message.Message()
    msg.add_header('From', config['from'])
    msg.add_header('To', config['to'])
    msg.add_header('Subject', get_subject(latest_status, latest_suites))
    body = get_msg_body(latest_status, latest_suites)
    if 'website' in config:
        body = config['website'] + '\n\n' + body
    msg.set_payload(body)

    c = email.charset.Charset('utf-8')
    c.body_encoding = None
    msg.set_charset(c)

    smtp_func = smtplib.SMTP_SSL if config['ssl'] else emtplib.SMTP
    s = smtp_func(config['server'], config['port'])
    s.login(config['user'], config['pass'])
    s.sendmail(config['from'], config['to'], msg.as_string().encode('utf-8'))


if __name__ == '__main__':
    args = parse_args()

    testParser = util.testresults.ETreeTestParser()

    prev_name = get_last_reported(args.latest)
    prev_suites = None
    try:
        prev_suites = util.testresults.getTestSuitesAndTestCases(
                args.containing_dir, prev_name, testParser)
    except:
        pass

    dirs = util.testresults.get_ecltest_dirs(args.containing_dir, 1)
    if not dirs:
        exit()
    latest_name = dirs[0]

    latest_suites = util.testresults.getTestSuitesAndTestCases(
            args.containing_dir, latest_name, testParser)
    latest_status = util.testresults.get_ecltest_result(
            args.containing_dir, latest_name)

    if prev_name or args.email_on_first_run:
        if latest_name != prev_name:
            send_email(latest_status, latest_suites, prev_suites, args.config)
            write_last_reported(args.latest, latest_name)
    else:
        write_last_reported(args.latest, latest_name)
