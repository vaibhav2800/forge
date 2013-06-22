#! /usr/bin/env python3

import argparse
import io
import sys


def parse_args():
    parser = argparse.ArgumentParser(
            description='Word or character frequency counter')
    parser.add_argument('file', nargs='+', metavar='FILE',
            help='Read UTF-8 %(metavar)s. Pass ‘-’ for stdin.')
    parser.add_argument('-s', '--case-sensitive', action='store_true')
    parser.add_argument('-c', '--char', action='store_true',
            help='count characters not words')
    parser.add_argument('-q', '--dont-quote-words', action='store_true')
    parser.add_argument('-m', '--load-in-memory', action='store_true',
            help='''Load the full contents of each file in memory before
            processing it. May improve performance for large files but you must
            have enough free memory to load the largest file.''')
    parser.add_argument('-n', type=int, metavar='N', default=0,
            help='''Show top %(metavar)s results, default %(default)s.
            Set to 0 to show all results.''')
    parser.add_argument('-t', '--tab', action='store_true',
            help='Separate word from count by a tab instead of a space')

    args = parser.parse_args()
    if args.n < 0:
        print('Invalid -n value', args.n, 'must be > 0', file=sys.stderr)
        sys.exit(1)
    return args


class BaseCounter():

    def __init__(self, case_sensitive=False, load_in_memory=False):
        self.case_sensitive = case_sensitive
        self.load_in_memory = load_in_memory
        self._word_counts = {}

    def read(self, stream):
        if self.load_in_memory:
            self.read_string(stream.read())
        else:
            self.read_stream(stream)

    def read_string(self, string):
        raise NotImplementedError

    def read_stream(self, stream):
        raise NotImplementedError

    def add(self, word, do_not_alter=False):
        if not do_not_alter:
            if not self.case_sensitive:
                word = word.lower()
        if not word in self._word_counts:
            self._word_counts[word] = 0
        self._word_counts[word] += 1

    def get_word_counts(self):
        return dict(self._word_counts)

    class _WordCount:

        def __init__(self, word, count):
            self.word, self.count = word, count

    def get_sorted_words(self):
        word_list = [BaseCounter._WordCount(i[0], i[1])
                for i in self._word_counts.items()]
        word_list.sort(key=lambda x: x.count, reverse=True)
        return word_list

    def word_count(self):
        '''Word count of scanned text. Includes duplicates.'''
        return sum(self._word_counts.values())

    def unique_word_count(self):
        '''Number of unique words.'''
        return len(self._word_counts)


class CharCounter(BaseCounter):

    def __init__(self, **args):
        super().__init__(**args)

    def read_stream(self, stream):
        while True:
            c = stream.read(1)
            if not c:
                break
            self.add(c)

    def read_string(self, string):
        for c in string:
            self.add(c)


class WordCounter(BaseCounter):

    def __init__(self, **args):
        super().__init__(**args)

    def read_stream(self, stream):
        buf = io.StringIO()
        while True:
            c = stream.read(1)
            if c.isalpha():
                buf.write(c)
            elif buf.tell():
                self.add(buf.getvalue())
                buf.seek(0)
                buf.truncate()
            if not c:
                break
        buf.close()

    def read_string(self, string):
        i = -1
        for j in range(len(string)):
            if string[j].isalpha():
                if i == -1:
                    i = j
            else:
                if i != -1:
                    self.add(string[i:j])
                    i = -1
        if i != -1:
            self.add(string[i:])


if __name__ == '__main__':
    args = parse_args()
    class_ = CharCounter if args.char else WordCounter
    counter = class_(case_sensitive=args.case_sensitive,
            load_in_memory=args.load_in_memory)

    for filename in args.file:
        if filename == '-':
            counter.read(sys.stdin)
        else:
            with open(filename, encoding='utf=8') as stream:
                counter.read(stream)
    
    print(counter.word_count(), ('characters' if args.char else 'words') + ',',
            counter.unique_word_count(), 'unique', end='')
    results = counter.get_sorted_words()
    if args.n:
        print(', showing top', args.n, end='')
        results = results[:args.n]
    print()

    sep = '\t' if args.tab else ' '
    for x in results:
        word = repr(x.word)
        if args.dont_quote_words:
            word = word[1:-1]
        print(word, x.count, sep=sep)
