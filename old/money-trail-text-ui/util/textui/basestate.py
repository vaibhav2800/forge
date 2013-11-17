# Copyright © Mihai Borobocea 2011
#
# This file is part of Money Trail.
#
# Money Trail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Money Trail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Money Trail.  If not, see <http://www.gnu.org/licenses/>.

class BaseState:
    '''Lays out the structure for all classes representing a textui state.'''

    def getEntryMsg(self):
        '''The message to display when entering the state, or None/empty.'''

        return None


    def printEntryMsg(self):
        '''Prints the entry msg with spacing, if the msg is present.'''

        msg = self.getEntryMsg()
        if (msg):
            print('–' * 79)
            print()
            print(msg)
            print()
            print()


    def _transition(self, inp):
        '''Do any work needed for input and return the next state object.

        Must be overridden by subclasses to perform any necessary work for
        input 'inp' and return the next state.
        Subclasses who need to print an optional message when leaving the state
        should do so at the end of this method.
        '''

        raise Exception('derived textui states must override _transition()')


    def _getInput(self):
        '''Get selected option or input text from the user.

        Should only be implemented by InputState and OptionState.
        This method may prompt the user multiple times until a valid input is
        obtained, depending on the configuration of each state. See InputState
        and OptionState for more info.'''

        raise Exception('_getInput() not implemented in BaseState')


    def getNextState(self):
        '''Get next state after printing entry msg and getting user input.

        Subclasses shouldn't need to override this method.'''

        self.printEntryMsg()
        return self._transition(self._getInput())


class InputState(BaseState):
    '''Asks user to enter text, can be configured to accept an empty line.'''

    def __init__(self, prompt, end=':', requireNonEmpty=True):
        self.prompt = prompt + end + ' '
        self.requireNonEmpty = requireNonEmpty


    def _getInput(self):
        inp = input(self.prompt)
        if self.requireNonEmpty:
            while not inp:
                inp = input(self.prompt)
        return inp


class OptionState(BaseState):
    '''Prompts user to select one option from a list, permits a default'''

    def __init__(self, options, default=None, prompt='Choose an option',
            end=':', nolist=False):
        '''Init from a dictionary of options and other config args.

        The options arg maps strings of length 1 to option descriptions.'''

        if not options:
            raise ValueError('Empty options supplied to OptionState')
        for key in options:
            if len(key) != 1:
                raise ValueError("Option key '{}' not of length 1".format(key))
        if default and default not in options:
            raise ValueError("Invalid default '{}' for options {}".format(
                default, options))

        self.options = options
        self.default = default

        prompt += ' [' + ','.join(options) + ']'
        if default:
            prompt += ' [default ' + default + ']'
        self.prompt = prompt + end + ' '

        self.nolist = nolist


    def _printOptions(self):
        for k, v in self.options.items():
            print(k, '*' if k == self.default else '–', v)


    def _getInput(self):
        if not self.nolist:
            self._printOptions()
        print()
        inp = input(self.prompt)
        while inp not in self.options:
            if self.default and not inp:
                return self.default
            else:
                inp = input(self.prompt)
        return inp
