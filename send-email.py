#! /usr/bin/env python3

import argparse
import email.message
from email.utils import COMMASPACE
import getpass
import smtplib


def parse_args():
    parser = argparse.ArgumentParser(description='Send Email')

    parser.add_argument('server', help='SMTP email server')
    parser.add_argument('-p', '--port', type=int, help='port')
    parser.add_argument('--ssl', action='store_true', help='Use SSL')
    parser.add_argument('-u', '--user', required=True, help='username')
    parser.add_argument('--from', dest='from_addr', metavar='FROM',
            required=True, help='From email address')
    parser.add_argument('--to', required=True, nargs='+',
            help='To email address(es)')
    parser.add_argument('-s', '--subject', required=True, help='Subject')
    parser.add_argument('-m', '--message', required=True, help='Message body')

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    msg = email.message.Message()
    msg.add_header('From', args.from_addr)
    msg.add_header('To', COMMASPACE.join(args.to))
    msg.add_header('Subject', args.subject)
    msg.set_payload(args.message)

    c = email.charset.Charset('utf-8')
    c.body_encoding = None
    msg.set_charset(c)

    smtp_args = (args.server, args.port) if args.port else (args.server,)
    smtp_func = smtplib.SMTP_SSL if args.ssl else smtplib.SMTP
    s = smtp_func(*smtp_args)

    s.login(args.user, getpass.getpass())
    s.sendmail(args.from_addr, args.to, msg.as_string().encode('utf-8'))
