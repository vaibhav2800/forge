import calendar
import time
import xml.dom.minidom
import xml.dom.pulldom
import xml.etree.ElementTree


class TestSuite():
    '''A completed test suite having several test cases'''


    def __init__(self, name, nTests, nErr, nFail, seconds, timestamp):
        self.name = name
        self.nTests = nTests
        self.nErr = nErr
        self.nFail = nFail
        self.seconds = seconds
        self.timestamp = timestamp
        self.testcases = []


class TestCase():


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
                int(float(d['time'])),
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
                int(float(d['time'])),
                _suite_tstamp_to_local_time(d['timestamp']))

        for d in d['testcases']:
            test = TestCase(d['name'],
                    int(float(d['time'])),
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
        for c in e.childNodes:
            if c.nodeType != c.ELEMENT_NODE or c.tagName != 'testcase':
                continue

            err_msg = fail_msg = None
            for nested in c.childNodes:
                if nested.nodeType != nested.ELEMENT_NODE:
                    continue
                if nested.tagName == 'error':
                    for x in nested.childNodes:
                        if x.nodeType == x.TEXT_NODE:
                            err_msg = x.nodeValue
                    break
                if nested.tagName == 'failure':
                    for x in nested.childNodes:
                        if x.nodeType == x.TEXT_NODE:
                            fail_msg = x.nodeValue
                    break

            testcases.append({'name': c.getAttribute('name'),
                'time': c.getAttribute('time'),
                'errorMsg': err_msg,
                'failureMsg': fail_msg})

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
        for c in list(r):
            if c.tag != 'testcase':
                continue

            errorMsg = failureMsg = None

            for x in list(c):
                if x.tag == 'error':
                    errorMsg = x.text
                    break
                if x.tag == 'failure':
                    failureMsg = x.text
                    break

            testcases.append({
                'name': c.attrib['name'],
                'time': c.attrib['time'],
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
