import calendar
import os
import time
import xml.dom.minidom
import xml.dom.pulldom
import xml.etree.ElementTree


def get_ecltest_dirs(containing_dir, N=50):
    '''Gets N result dirs, in reverse lexicographical order.

    Throws OSError.
    '''
    dirs = []
    items = os.listdir(containing_dir)
    items.sort(reverse=True)
    for x in items:
        if os.path.exists(os.path.join(containing_dir, x, 'ECLTEST_RESULT')):
            dirs.append(x)
            if len(dirs) >= N:
                break

    return dirs[:N]


def get_ecltest_result(containing_dir, dirname):
    '''Returns the contents of the ECLTEST_RESULT file.

    Throws OSError, IOError.'''

    filepath = os.path.join(containing_dir, dirname, 'ECLTEST_RESULT')
    with open(filepath, encoding='utf-8') as f:
        return f.read()


def getTestSuitesOnly(containing_dir, dirname, testParser):
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


def getTestSuitesAndTestCases(containing_dir, dirname, testParser):
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


def _getGlobalProblemName(N):
    '''Returns a name for the N-th global <failure> or <error> message.

    If @BeforeClass throws an Exception, the XML contains a <failure> tag
    without a parent <testcase> tag.
    If extending TestSuite and throwing an exception from the static suite()
    method, the XML needs no special attention: the <failure> tag has a parent
    <testcase> tag called 'initializationError'.

    Use this function to treat each global <failure> or <error> message
    like it had a parent <testcase> with the name returned by this function.
    '''

    # don't append a suffix for the first failure (we only expect to find 1)
    if N == 1:
        return '!initializationError'
    else:
        return '!initializationError.' + str(N)


class TestSuite():
    '''A completed test suite having several test cases.

    Field .seconds is a float.
    '''


    def __init__(self, name, nTests, nErr, nFail, seconds, timestamp):
        self.name = name
        self.nTests = nTests
        self.nErr = nErr
        self.nFail = nFail
        self.seconds = seconds
        self.timestamp = timestamp
        self.testcases = []


class TestCase():
    '''A testcase.

    Field .time is a float.
    '''


    def __init__(self, name, time, errorMsg, failureMsg):
        '''Creates a new TestCase.

        At most one of errorMsg or failureMsg can be different from None which
        means this test has not passed.
        '''

        if errorMsg is not None and failureMsg is not None:
            raise ValueError('TestCase cannot be both error and failure')

        self.name = name
        self.time = time
        self.err = errorMsg
        self.fail = failureMsg


def _suite_tstamp_to_local_time(timestamp):
    # XML timestamp is in UTC, but has no explicit offset
    struct_time = time.strptime(timestamp, '%Y-%m-%dT%H:%M:%S')
    seconds_since_epoch = calendar.timegm(struct_time)
    struct_time = time.localtime(seconds_since_epoch)
    return time.strftime('%Y.%m.%d-%H:%M:%S', struct_time)


class TestParser():
    '''Abstract base class for parsing Test Suite XML files.'''


    def getTestSuiteOnly(self, filename):
        '''Parses filename and returns a TestSuite without TestCases.'''
        d = self._parseSuiteOnly(filename)
        return TestSuite(d['name'],
                int(d['tests']),
                int(d['errors']),
                int(d['failures']),
                float(d['time']),
                _suite_tstamp_to_local_time(d['timestamp']))


    def _parseSuiteOnly(self, filename):
        '''Parses filename and returns a dictionary for the suite summary.

        The returned dictionary must have string values and
        the following string keys:
        name, tests, errors, failures, time, timestamp
        '''
        raise NotImplementedError()


    def getTestSuiteWithTestCases(self, filename):
        '''Parses filename and returns a TestSuite with TestCases.'''
        d = self._parseSuiteWithTestCases(filename)
        suite = TestSuite(d['name'],
                int(d['tests']),
                int(d['errors']),
                int(d['failures']),
                float(d['time']),
                _suite_tstamp_to_local_time(d['timestamp']))

        for d in d['testcases']:
            test = TestCase(d['name'],
                    float(d['time']),
                    d['errorMsg'],
                    d['failureMsg'])
            suite.testcases.append(test)

        return suite


    def _parseSuiteWithTestCases(self, filename):
        '''Parses filename and returns a dictionary.

        The returned dictionary must have all the keys returned by
        _parseSuiteOnly. In addition it must have a key 'testcases' whose
        value is a list of dictionaries, each representing a TestCase.
        A dictionary representing a TestCase must have string values and
        the following string keys:
        name, time, errorMsg, failureMsg
        At most 1 of errorMsg and failureMsg can be different from None.
        '''
        raise NotImplementedError()


class MinidomTestParser(TestParser):
    '''TestParser implementation using xml.dom.minidom'''


    def _parseSuiteOnly(self, filename):
        doc = xml.dom.minidom.parse(filename)
        e = doc.documentElement
        return {'name': e.getAttribute('name'),
                'tests': e.getAttribute('tests'),
                'errors': e.getAttribute('errors'),
                'failures': e.getAttribute('failures'),
                'time': e.getAttribute('time'),
                'timestamp': e.getAttribute('timestamp')}


    def _parseSuiteWithTestCases(self, filename):
        doc = xml.dom.minidom.parse(filename)
        e = doc.documentElement

        testcases = []
        globalProblems = 0
        for c in e.childNodes:
            if c.nodeType != c.ELEMENT_NODE:
                continue

            name = ''
            time = '0'
            err_msg = fail_msg = None

            if c.tagName == 'testcase':
                name = c.getAttribute('name')
                time = c.getAttribute('time')
                for nested in c.childNodes:
                    if nested.nodeType != nested.ELEMENT_NODE:
                        continue
                    if nested.tagName == 'error':
                        for x in nested.childNodes:
                            if x.nodeType == x.TEXT_NODE:
                                err_msg = x.nodeValue
                                break
                        break
                    if nested.tagName == 'failure':
                        for x in nested.childNodes:
                            if x.nodeType == x.TEXT_NODE:
                                fail_msg = x.nodeValue
                                break
                        break
            elif c.tagName == 'failure' or c.tagName == 'error':
                globalProblems += 1
                name = _getGlobalProblemName(globalProblems)
                for x in c.childNodes:
                    if x.nodeType == x.TEXT_NODE:
                        if c.tagName == 'failure':
                            fail_msg = x.nodeValue
                        else:
                            err_msg = x.nodeValue
                        break
            else:
                continue

            testcases.append({
                'name': name,
                'time': time,
                'errorMsg': err_msg,
                'failureMsg': fail_msg
                })

        return {'name': e.getAttribute('name'),
                'tests': e.getAttribute('tests'),
                'errors': e.getAttribute('errors'),
                'failures': e.getAttribute('failures'),
                'time': e.getAttribute('time'),
                'timestamp': e.getAttribute('timestamp'),
                'testcases': testcases}


class ETreeTestParser(TestParser):
    '''TestParser implementation using xml.etree.ElementTree'''


    def _parseSuiteOnly(self, filename):

        et = xml.etree.ElementTree.parse(filename)
        r = et.getroot()
        return {'name': r.attrib['name'],
                'tests': r.attrib['tests'],
                'errors': r.attrib['errors'],
                'failures': r.attrib['failures'],
                'time': r.attrib['time'],
                'timestamp': r.attrib['timestamp']}


    def _parseSuiteWithTestCases(self, filename):
        '''Parses filename and returns a dictionary.

        The returned dictionary must have all the keys returned by
        _parseSuiteOnly. In addition it must have a key 'testcases' whose
        value is a list of dictionaries, each representing a TestCase.
        A dictionary representing a TestCase must have string values and
        the following string keys:
        name, time, errorMsg, failureMsg
        At most 1 of errorMsg and failureMsg can be different from None.
        '''

        et = xml.etree.ElementTree.parse(filename)
        r = et.getroot()

        testcases = []
        globalProblems = 0
        for c in list(r):
            name = ''
            time = '0'
            errorMsg = failureMsg = None

            if c.tag == 'testcase':
                name = c.attrib['name']
                time = c.attrib['time']

                for x in list(c):
                    if x.tag == 'error':
                        errorMsg = x.text
                        break
                    if x.tag == 'failure':
                        failureMsg = x.text
                        break
            elif c.tag == 'failure' or c.tag == 'error':
                globalProblems += 1
                name = _getGlobalProblemName(globalProblems)
                if c.tag == 'failure':
                    failureMsg = c.text
                else:
                    errorMsg = c.text
            else:
                continue

            testcases.append({
                'name': name,
                'time': time,
                'errorMsg': errorMsg,
                'failureMsg': failureMsg
                })

        return {'name': r.attrib['name'],
                'tests': r.attrib['tests'],
                'errors': r.attrib['errors'],
                'failures': r.attrib['failures'],
                'time': r.attrib['time'],
                'timestamp': r.attrib['timestamp'],
                'testcases': testcases}


class PulldomTestParser(TestParser):
    '''Incomplete TestParser implementation using xml.dom.pulldom.

    This class implements only the _parseSuiteOnly method.
    It can be paired up with another implementation (via multiple inheritance).
    '''


    def _parseSuiteOnly(self, filename):
        event_stream = xml.dom.pulldom.parse(filename)
        i = 0
        for ev, elem in event_stream:
            if i == 1:
                if ev != xml.dom.pulldom.START_ELEMENT:
                    raise ValueError('Unexpected XML structure')
                return {'name': elem.getAttribute('name'),
                        'tests': elem.getAttribute('tests'),
                        'errors': elem.getAttribute('errors'),
                        'failures': elem.getAttribute('failures'),
                        'time': elem.getAttribute('time'),
                        'timestamp': elem.getAttribute('timestamp')}
            i += 1
        raise ValueError('Unexpected XML structure')


class PulldomETreeTestParser(PulldomTestParser, ETreeTestParser):
    '''TestParser implementation using Pulldom and ETree.'''
    pass
