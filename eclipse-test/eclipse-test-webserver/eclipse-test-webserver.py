#! /usr/bin/env python3

import argparse
import os
import http.server

import util.testresults
import util.fmt


def parse_args():
    parser = argparse.ArgumentParser(description='Eclipse-Test web server')
    parser.add_argument('containing_dir',
            help='''
            directory containing the output directories produced by
            eclipse-test.py, one for each test run.
            ''')
    parser.add_argument('port', type=int, help='port to listen on')
    parser.add_argument('--color-pass', default='green',
            help='HTML color name for passes, default %(default)s.')
    parser.add_argument('--color-fail', default='red',
            help='HTML color name for failures, default %(default)s.')
    parser.add_argument('--color-detail', default='Crimson',
            help='HTML color name for failure details, default %(default)s.')
    return parser.parse_args()


def get_ecltest_dirs(N=50):
    '''Gets N result dirs, in reverse lexicographical order.

    Throws OSError.
    '''
    dirs = []
    for x in os.listdir(containing_dir):
        if os.path.exists(os.path.join(containing_dir, x, 'ECLTEST_RESULT')):
            dirs.append(x)

    dirs.sort(reverse=True)
    return dirs[:N]


def get_ecltest_result(dirname):
    '''Returns the contents of the ECLTEST_RESULT file.

    Throws OSError, IOError.'''

    filepath = os.path.join(containing_dir, dirname, 'ECLTEST_RESULT')
    with open(filepath, encoding='utf-8') as f:
        return f.read()


def getTestSuitesOnly(dirname):
    '''Returns a list of TestSuites without TestCases parsed from dirname.'''

    suites = []
    dirpath = os.path.join(containing_dir, dirname)
    for path in os.listdir(dirpath):
        if path != 'ECLTEST_RESULT':
            try:
                fullPath = os.path.join(dirpath, path)
                suites.append(testParser.getTestSuiteOnly(fullPath))
            except:
                # handle empty documents
                pass
    suites.sort(key=lambda x: x.name)
    return suites


def getTestSuitesAndTestCases(dirname):
    '''Returns a list of TestSuites with TestCases parsed from dirname.'''

    suites = []
    dirpath = os.path.join(containing_dir, dirname)
    for path in os.listdir(dirpath):
        if path == 'ECLTEST_RESULT':
            continue
        try:
            fullPath = os.path.join(dirpath, path)
            suites.append(testParser.getTestSuiteWithTestCases(fullPath))
        except:
            # handle empty documents
            pass
    suites.sort(key=lambda x: x.name)
    return suites


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

        path = self.path.strip('/')
        for dirname in get_ecltest_dirs():
            if dirname == path:
                self.show_result_dir(dirname)
                return

        self.send_not_found()


    def send_dir_list(self):
        self.send_response_only(200, "OK")
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.wfile.write('\r\n'.encode('utf-8'))

        self.wfile.write(
                util.fmt.get_html_start('Available Test Runs',
                    **colors).encode('utf-8'))

        dirs = get_ecltest_dirs()
        if dirs:
            for d in dirs:
                self.print_dir_link(d)
        else:
            self.wfile.write(('<p>No completed test runs found in ' +
                html.escape(os.path.abspath(containing_dir)) +
                '</p>').encode('utf-8'))

        self.wfile.write(util.fmt.html_end.encode('utf-8'))


    def print_dir_link(self, dirname, sep1=' – ', sep2=' '):
        descr_items = []
        totalT = totalE = totalF = 0

        for suite in getTestSuitesOnly(dirname):
            totalT += suite.nTests
            totalE += suite.nErr
            totalF += suite.nFail

            descr_items.append(util.fmt.get_suite_link(dirname, suite))

        run_crashed = not get_ecltest_result(dirname).startswith('OK\n')
        allPassed = not (totalE or totalF or run_crashed)
        dir_link = util.fmt.get_dir_link(dirname, allPassed)

        text = dir_link + sep1 + sep2.join(descr_items) + '<br/>\n'
        self.wfile.write(text.encode('utf-8'))


    def show_result_dir(self, dirname):
        self.send_response_only(200, "OK")
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.wfile.write('\r\n'.encode('utf-8'))

        self.wfile.write(
                util.fmt.get_html_start(dirname, **colors).encode('utf-8'))
        self.wfile.write('<p><a href="/">← Back Home</a></p>'.encode('utf-8'))
        self.print_dir_link(dirname)
        self.wfile.write(util.fmt.result_dir_start.encode('utf-8'))

        ecltest_result = get_ecltest_result(dirname)
        self.wfile.write(
                util.fmt.get_ecltest_result(ecltest_result).encode('utf-8'))

        for suite in getTestSuitesAndTestCases(dirname):
            self.print_suite(suite)

        self.wfile.write(util.fmt.html_end.encode('utf-8'))


    def print_suite(self, suite):
        self.wfile.write(util.fmt.get_suite_heading(suite).encode('utf-8'))
        self.wfile.write(util.fmt.get_suite_summary(suite).encode('utf-8'))
        self.wfile.write('<table border="1">'.encode('utf-8'))
        for testCase in suite.testcases:
            self.wfile.write(
                    util.fmt.get_testcase_row(testCase).encode('utf-8'))
        self.wfile.write('</table>'.encode('utf-8'))


if __name__ == '__main__':
    args = parse_args()

    global colors
    colors = {
            'color_pass': args.color_pass,
            'color_fail': args.color_fail,
            'color_detail': args.color_detail,
            }

    global containing_dir
    containing_dir = args.containing_dir

    global testParser
    testParser = util.testresults.ETreeTestParser()

    httpd = http.server.HTTPServer(("", args.port), EclTestHandler)
    httpd.serve_forever()
