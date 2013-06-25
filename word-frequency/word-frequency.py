#! /usr/bin/env python3

import argparse
from collections import deque
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
    parser.add_argument('-g', '--groups', action='store_true',
            help='''Also count groups: letter groups in word-counting mode,
            character groups in character-counting mode.''')
    parser.add_argument('--group-size', type=int, metavar='N', default=2,
            help='''Group size for counting letter- or character- groups,
            default %(default)s.''')
    parser.add_argument('-p', '--percentage', action='store_true',
            help='show frequency as percentage')
    parser.add_argument('-d', '--decimals', type=int, metavar='D',
            help='show frequency with %(metavar)s decimals')

    args = parser.parse_args()
    if args.n < 0:
        print('Invalid -n value', args.n, 'must be > 0', file=sys.stderr)
        sys.exit(1)
    if args.group_size < 2:
        print('Invalid group size', args.group_size, 'must be >= 2',
                file=sys.stderr)
        sys.exit(1)
    if args.decimals and args.decimals < 0:
        print('Invalid decimals', args.decimals, 'must be >= 0',
                file=sys.stderr)
        sys.exit(1)
    return args


class BaseCounter():

    def __init__(self, case_sensitive=False, load_in_memory=False,
            group_size=0):
        self.case_sensitive = case_sensitive
        self.load_in_memory = load_in_memory
        self._word_counts = {}

        self.group_size = group_size
        if group_size:
            self.group_counter = BaseCounter(case_sensitive=case_sensitive)

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
        if self.group_size:
            self.tail = deque([], self.group_size)

    def add(self, c, **args):
        super().add(c, **args)
        if self.group_size:
            self.tail.append(c)
            if len(self.tail) == self.group_size:
                self.group_counter.add(''.join(self.tail))

    def read(self, stream):
        if self.group_size:
            self.tail.clear()
        super().read(stream)

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

    def add(self, word, **args):
        super().add(word, **args)
        if self.group_size:
            for j in range(self.group_size, len(word) + 1):
                self.group_counter.add(word[j - self.group_size : j])

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
            load_in_memory=args.load_in_memory,
            group_size=args.group_size if args.groups else 0)

    for filename in args.file:
        if filename == '-':
            counter.read(sys.stdin)
        else:
            with open(filename, encoding='utf=8') as stream:
                counter.read(stream)

    def format_freq(n, total, as_percentage=False, decimals=None):
        freq = (n*100 if as_percentage else n) / total
        return (
                (('{:.' + str(decimals) + 'f}').format(freq)
                    if decimals is not None
                    else str(freq)) +
                ('%' if as_percentage else '')
                )

    def print_counter(cnt, items_name):
        total_items = cnt.word_count()
        print(total_items, items_name + ',',
                cnt.unique_word_count(), 'unique', end='')
        results = cnt.get_sorted_words()
        if args.n:
            print(', showing top', args.n, end='')
            results = results[:args.n]
        print()

        sep = '\t' if args.tab else ' '
        for x in results:
            word = repr(x.word)
            if args.dont_quote_words:
                word = word[1:-1]
            freq_str = format_freq(x.count, total_items,
                    args.percentage, args.decimals)
            print(word, x.count, freq_str, sep=sep)

    print_counter(counter, 'characters' if args.char else 'words')
    if args.groups:
        print()
        print_counter(counter.group_counter,
                ('character' if args.char else 'letter') + ' groups')
