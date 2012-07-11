#! /usr/bin/env python3

import argparse
import os
import html
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
        self.wfile.write(text.encode('utf-8'))


    def show_result_dir(self, dirname):
        self.send_response_only(200, "OK")
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.wfile.write('\r\n'.encode('utf-8'))

        self.wfile.write(util.fmt.get_html_start(
            dirname + ' (' + title + ')', **colors).encode('utf-8'))
        self.wfile.write('<p><a href="/">← Back Home</a></p>'.encode('utf-8'))
        self.print_dir_link(dirname)
        self.wfile.write(util.fmt.result_dir_start.encode('utf-8'))

        ecltest_result = \
                util.testresults.get_ecltest_result(containing_dir, dirname)
        self.wfile.write(
                util.fmt.get_ecltest_result(ecltest_result).encode('utf-8'))

        for suite in util.testresults.getTestSuitesAndTestCases(
                containing_dir, dirname, testParser):
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
            'color_title': args.color_title,
            }

    global containing_dir
    containing_dir = args.containing_dir

    global title
    title = args.title

    global testParser
    testParser = util.testresults.ETreeTestParser()

    httpd = http.server.HTTPServer(("", args.port), EclTestHandler)
    httpd.serve_forever()
