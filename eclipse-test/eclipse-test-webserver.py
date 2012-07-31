#! /usr/bin/env python3

import argparse
import os
import os.path
import html
import http.server

import util.testresults
import util.fmt


# change this whenever the Web content changes to discard the old cache
CACHE_VERSION = '1'


def parse_args():
    parser = argparse.ArgumentParser(description='Eclipse-Test web server')
    parser.add_argument('containing_dir',
            help='''
            directory containing the output directories produced by
            eclipse-test.py, one for each test run.
            ''')
    parser.add_argument('port', type=int, help='port to listen on')
    parser.add_argument('--cache-dir', help='''Dir holding a cache of the
            Web content to avoid reparsing old XML files on each request.
            This directory must exist.''')
    parser.add_argument('--color-pass', metavar='COLOR', default='green',
            help='HTML color name for passes, default %(default)s.')
    parser.add_argument('--color-fail', metavar='COLOR', default='red',
            help='HTML color name for failures, default %(default)s.')
    parser.add_argument('--color-detail', metavar='COLOR', default='Crimson',
            help='HTML color name for failure details, default %(default)s.')
    parser.add_argument('--color-title', metavar='COLOR', default='black',
            help='HTML color name for page title, default %(default)s.')
    parser.add_argument('--title', default='Eclipse-Test Results',
            help='Title for HTML pages, default %(default)s.')
    return parser.parse_args()


def get_mtime(filepath):
    '''Returns mtime or None.'''

    mtime = None
    try:
        mtime = os.stat(filepath).st_mtime
    except OSError:
        pass

    return mtime


def get_latest_timestamp(result_dir):
    '''
    Returns the latest mtime of any direct child of this result dir, or None.
    '''

    latest_time = None
    try:
        dirpath = os.path.join(containing_dir, result_dir)
        for f in os.listdir(dirpath):
            mtime = get_mtime(os.path.join(dirpath, f))
            if not latest_time or mtime > latest_time:
                latest_time = mtime
    except OSError:
        pass

    return latest_time


def get_cached_summary_path(dirname):
    return os.path.join(cache_dir, dirname + '-summary-' + CACHE_VERSION)


def get_dir_link(dirname, sep1, sep2):
    return get_cached_dir_link(dirname) or \
            generate_dir_link(dirname, sep1, sep2)


def get_cached_dir_link(dirname):
    if not cache_dir:
        return None

    result_time = get_latest_timestamp(dirname)
    if not result_time:
        return None

    cache_path = get_cached_summary_path(dirname)
    cache_time = get_mtime(cache_path)
    if not cache_time or cache_time <= result_time:
        return None

    with open(cache_path, encoding='utf-8') as f:
        return f.read()


def generate_dir_link(dirname, sep1, sep2):
    descr_items = []
    totalT = totalE = totalF = 0

    for suite in util.testresults.getTestSuitesOnly(
            containing_dir, dirname, testParser):
        totalT += suite.nTests
        totalE += suite.nErr
        totalF += suite.nFail

        descr_items.append(util.fmt.get_suite_link(dirname, suite))

    run_crashed = not util.testresults \
            .get_ecltest_result(containing_dir, dirname).startswith('OK\n')
    allPassed = not (totalE or totalF or run_crashed)
    dir_link = util.fmt.get_dir_link(dirname, allPassed)

    text = dir_link + sep1 + sep2.join(descr_items) + '<br/>\n'

    if cache_dir:
        try:
            with open(get_cached_summary_path(dirname), \
                    encoding='utf-8', mode='w') as f:
                f.write(text)
        except IOError:
            pass

    return text


def get_cached_resultdir_path(dirname):
    return os.path.join(cache_dir, dirname + '-full-' + CACHE_VERSION)


def get_resultdir_html(dirname):
    return get_cached_resultdir_html(dirname) or \
            generate_resultdir_html(dirname)


def get_cached_resultdir_html(dirname):
    if not cache_dir:
        return None

    result_time = get_latest_timestamp(dirname)
    if not result_time:
        return None

    cache_path = get_cached_resultdir_path(dirname)
    cache_time = get_mtime(cache_path)
    if not cache_time or cache_time <= result_time:
        return None

    with open(cache_path, encoding='utf-8') as f:
        return f.read()


def generate_resultdir_html(dirname):
    html = ''
    ecltest_result = \
            util.testresults.get_ecltest_result(containing_dir, dirname)
    html += util.fmt.get_ecltest_result(ecltest_result)

    for suite in util.testresults.getTestSuitesAndTestCases(
            containing_dir, dirname, testParser):
        html += get_suite_html(suite)

    if cache_dir:
        try:
            with open(get_cached_resultdir_path(dirname), \
                    encoding='utf-8', mode='w') as f:
                f.write(html)
        except IOError:
            pass

    return html


def get_suite_html(suite):
    html = ''
    html += util.fmt.get_suite_heading(suite)
    html += util.fmt.get_suite_summary(suite)
    html += '<table border="1">'
    for testCase in suite.testcases:
        html += util.fmt.get_testcase_row(testCase)
    html += '</table>'

    return html


class EclTestHandler(http.server.BaseHTTPRequestHandler):


    def send_not_found(self):
        self.send_response_only(404, "Not Found")
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.wfile.write('\r\n'.encode('utf-8'))
        self.wfile.write('Not Found'.encode('utf-8'))


    def do_GET(self):
        if self.path.strip('/') == '':
            self.send_dir_list()
            return

        try:
            path = self.path.strip('/')
            for dirname in util.testresults.get_ecltest_dirs(containing_dir):
                if dirname == path:
                    self.show_result_dir(dirname)
                    return
        except OSError:
            # get_ecltest_dirs throws OSError if containing_dir doesn't exist
            pass

        self.send_not_found()


    def send_dir_list(self):
        self.send_response_only(200, "OK")
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.wfile.write('\r\n'.encode('utf-8'))

        self.wfile.write(
                util.fmt.get_html_start(title, **colors).encode('utf-8'))

        dirs = None
        try:
            dirs = util.testresults.get_ecltest_dirs(containing_dir)
        except OSError:
            # get_ecltest_dirs throws OSError if containing_dir doesn't exist
            pass
        if dirs:
            for d in dirs:
                self.print_dir_link(d)
        else:
            self.wfile.write(('<p>No completed test runs found in ' +
                html.escape(os.path.abspath(containing_dir)) +
                '</p>').encode('utf-8'))

        self.wfile.write(util.fmt.html_end.encode('utf-8'))


    def print_dir_link(self, dirname, sep1=' – ', sep2=' '):
        self.wfile.write(get_dir_link(dirname, sep1, sep2).encode('utf-8'))


    def show_result_dir(self, dirname):
        self.send_response_only(200, "OK")
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.wfile.write('\r\n'.encode('utf-8'))

        self.wfile.write(util.fmt.get_html_start(
            dirname + ' (' + title + ')', **colors).encode('utf-8'))
        self.wfile.write('<p><a href="/">← Back Home</a></p>'.encode('utf-8'))
        self.print_dir_link(dirname)
        self.wfile.write(util.fmt.result_dir_start.encode('utf-8'))

        self.wfile.write(get_resultdir_html(dirname).encode('utf-8'))

        self.wfile.write(util.fmt.html_end.encode('utf-8'))


if __name__ == '__main__':
    args = parse_args()

    global colors
    colors = {
            'color_pass': args.color_pass,
            'color_fail': args.color_fail,
            'color_detail': args.color_detail,
            'color_title': args.color_title,
            }

    global containing_dir
    containing_dir = args.containing_dir

    global cache_dir
    cache_dir = args.cache_dir

    global title
    title = args.title

    global testParser
    testParser = util.testresults.ETreeTestParser()

    httpd = http.server.HTTPServer(("", args.port), EclTestHandler)
    httpd.serve_forever()
