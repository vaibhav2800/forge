from collections import deque
from collections import OrderedDict
import datetime
import html
from string import Template


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


def humantime(seconds, beforeUnit='', sep=' ',
        noLeadZero=True, noTrailZero=True):
    return humansize(seconds, OrderedDict((('s', 1), ('m', 60), ('h', 60))),
            beforeUnit, sep, noLeadZero, noTrailZero)


def float_humantime(seconds_float, beforeUnit='', sep=' ',
        noLeadZero=True, noTrailZero=True):
    if seconds_float >= 1:
        return humantime(int(seconds_float), beforeUnit, sep,
                noLeadZero, noTrailZero)
    else:
        return str(seconds_float) + ' s'


html_start_templ = Template('''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8"/>
            <title>$title</title>
            <style type="text/css">
                h3.title { text-align: center; color: $color_title; }
                a.dir-suite-passed { color: $color_pass; }
                a.dir-suite-failed { color: $color_fail; }

                p.plain-text { white-space: pre; font-family: monospace; }

                tr.good_row td, tr.bad_row td { border-color: black; }
                tr.good_row td + td { color: $color_pass; }
                tr.bad_row td + td a { color: $color_fail; font-weight: bold; }
                tr.bad_row a { text-decoration: none; }
                tr.bad_row a:hover { text-decoration: underline; }
                tr.bad_detail_row { color: $color_detail; }

                td.testcase-time { text-align: right; font-family: monospace; }
            </style>
        </head>
        <body>

        <script type="text/javascript">
            good_rows_hidden = false;
            function toggle_good_rows() {
                good_rows_hidden = ! good_rows_hidden;
                var rows = document.getElementsByClassName('good_row');
                for (var i = 0; i < rows.length; i++)
                    rows[i].hidden = good_rows_hidden;
            }

            bad_detail_rows_hidden = false;
            function toggle_bad_detail_rows() {
                bad_detail_rows_hidden = ! bad_detail_rows_hidden;
                var rows = document.getElementsByClassName('bad_detail_row');
                for (var i = 0; i < rows.length; i++)
                    rows[i].hidden = bad_detail_rows_hidden;
            }

            function toggle_failure_detail(x) {
                x = x.parentNode.parentNode;
                x.nextElementSibling.hidden = !x.nextElementSibling.hidden;
            }
        </script>

        <h3 class="title">$title</h3>
        ''')


def get_html_start(title, color_pass, color_fail, color_detail, color_title):
    return html_start_templ.substitute({
        'title': html.escape(title),
        'color_pass': color_pass,
        'color_fail': color_fail,
        'color_detail': color_detail,
        'color_title': color_title,
        })


html_end = '''
        <script type="text/javascript">
            toggle_good_rows();
            toggle_bad_detail_rows();
        </script>
        </body>
        </html>
        '''


suite_link_templ = Template(
        '<a class="$class" href="/$dirname#$suitename">$suitename ($nums)</a>')


def get_suite_link(dirname, suite):
    '''Gets the HTML code for a link to a TestSuite.'''

    nBad = suite.nErr + suite.nFail
    return suite_link_templ.substitute({
        'class': 'dir-suite-failed' if nBad else 'dir-suite-passed',
        'dirname': html.escape(dirname),
        'suitename': html.escape(suite.name),
        'nums': (str(nBad)+' / '+str(suite.nTests)) if nBad else suite.nTests
        })


dir_link_templ = Template('''
        <a class="$class" href="/$dirname">$dirname</a>
        ''')


def get_dir_link(dirname, allPassed):
    '''Gets the HTML code for a link to dirname containing test suites.'''

    return dir_link_templ.substitute({
        'class': 'dir-suite-passed' if allPassed else 'dir-suite-failed',
        'dirname': html.escape(dirname)
        })


result_dir_start = '''
        <p>
        <button type="button" onclick="toggle_good_rows()">
            Toggle Passed Tests
        </button>
        <button type="button" onclick="toggle_bad_detail_rows()">
            Toggle Failure Details
        </button>
        </p>
        '''


ecltest_result_templ = Template(
        '<p class="plain-text">$ecltest_result</p>\n')


def get_ecltest_result(ecltest_result):
    '''Returns HTML code for the ecltest result paragraph'''
    return ecltest_result_templ.substitute({
        'ecltest_result': html.escape(ecltest_result)
        })


suite_heading_templ = Template('<h2 id="$name">$name</h2>')


def get_suite_heading(suite):
    return suite_heading_templ.substitute({'name': html.escape(suite.name)})


suite_summary_templ = Template('''
        <p>$total tests, $err errors, $fail failures</p>
        <p>Run time $runtime, started at $starttime</p>
        ''')


def get_suite_summary(suite):
    return suite_summary_templ.substitute({
        'total': suite.nTests,
        'err': suite.nErr,
        'fail': suite.nFail,
        'runtime':
            html.escape(str(datetime.timedelta(seconds=int(suite.seconds)))),
        'starttime': html.escape(suite.timestamp)
        })


testcase_good_row_templ = Template('''
        <tr class="good_row">
            <td class="testcase-time">$time</td>
            <td>
                $name
            </td>
        </tr>
        ''')

testcase_bad_row_templ = Template('''
        <tr class="bad_row">
            <td class="testcase-time">$time</td>
            <td>
                <a href="#"
                    onclick="toggle_failure_detail(this); return false;">
                    $name
                </a>
            </td>
        </tr>
        <tr class="bad_detail_row">
            <td colspan="2">
                $problem_type
                <p class="plain-text">$problem_msg</p>
            </td>
        </tr>
        ''')

def get_testcase_row(tc):
    if tc.err is None and tc.fail is None:
        return testcase_good_row_templ.substitute({
            'time': float_humantime(tc.time),
            'name': html.escape(tc.name)
            })
    else:
        return testcase_bad_row_templ.substitute({
            'time': float_humantime(tc.time),
            'name': html.escape(tc.name),
            'problem_type': 'error' if tc.err is not None else 'failure',
            'problem_msg': html.escape(
                tc.err if tc.err is not None else tc.fail)
            })
