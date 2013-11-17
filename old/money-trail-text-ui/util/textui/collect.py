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

import datetime
import os, sys
from collections import OrderedDict
from .basestate import BaseState, InputState, OptionState


class CollectDataState(BaseState):
    '''Base class for collecting user input and performing a final action.

    Requires a list of Bounce*State objects and transitions back-and-forth
    with all of them to collect data in self.collectedData.
    It then decides whether to make a final bounce to a BounceActionState
    (by default if all self.collectedData[BounceInputState.key] are non-empty)
    before returning to this state's parent state.
    If skipping the BounceActionState, a message can be optionally displayed.

    CollectDataState requires Bounce*States in its constructor, while those
    require CollectDataState in their constructor.
    The practice is for subclasses of CollectDataState to create all the
    Bounce*State objects passing 'self' as their parent, then pass those to
    CollectDataState.__init__(self, ...).
    '''

    def __init__(self, parentState, userDataStates, actionState):
        self.parentState = parentState
        self.collectedData = dict()
        self.userDataStates = userDataStates
        self.nextStateIdx = 0
        self.actionState = actionState
        self.actionPending = True
        self.entered = False
        # should be set to explain why the action state was skipped, or None
        self.skipMsg = 'Skipping action because some input data was empty.'


    def getNextState(self):
        if not self.entered:
            self.printEntryMsg()
            self.entered = True

        if self.nextStateIdx < len(self.userDataStates):
            next_state = self.userDataStates[self.nextStateIdx]
            self.nextStateIdx += 1
            return next_state

        if self.actionPending:
            self.actionPending = False
            if self.actionRequired():
                return self.actionState
            else:
                if self.skipMsg:
                    print()
                    print(self.skipMsg)
                    input('[Hit ENTER to continue] ')

        return self.parentState


    def actionRequired(self):
        '''Whether to transition to or skip the action state.

        Can be overridden by subclasses for custom logic.
        Default implementation checks that all BounceInputStates have gotten
        non-empty input.
        Called once after all BounceInputStates and BounceOptionStates have
        finished.
        '''

        for dataState in self.userDataStates:
            if isinstance(dataState, BounceInputState):
                if not self.collectedData[dataState.key]:
                    return False
        return True


class BounceInputState(InputState):
    '''Gets user input and transitions back to the parent state.

    Allows empty input and a default value to be substituted for empty input.
    Sets parentState.collectedData[key] = user_input and transitions back to
    the parent state.
    '''

    def __init__(self, parentState, key, prompt, default=''):
        self.parentState = parentState
        self.key = key
        if default:
            prompt = prompt + ' [default ' + default + ']'
        self.default = default
        InputState.__init__(self, prompt, requireNonEmpty=False)


    def _transition(self, inp):
        self.parentState.collectedData[self.key] = inp if inp else self.default
        return self.parentState


class BounceOptionState(OptionState):
    '''Gets option from user and transitions back to the parent state.

    Requires default option. Sets parentState.collectedData[key] = user_input
    and transitions back to the parent state.
    '''

    def __init__(self, parentState, key, options, default, **kwargs):
        # kwargs allows passing optional 'prompt' and 'end' to OptionState
        # without changing the default values if the user omits them
        if not default:
            raise ValueError('BounceOptionState requires default option')

        OptionState.__init__(self, options, default, **kwargs)
        self.parentState = parentState
        self.key = key


    def _transition(self, inp):
        self.parentState.collectedData[self.key] = inp
        return self.parentState


class BounceActionState(OptionState):
    '''Performs a custom action then transitions back to the parent state.

    Can optionally ask for confirmation.
    '''

    def __init__(self, parentState, prompt=None):
        if prompt:
            self.mustConfirm = True
            options = OrderedDict((('y', 'yes'), ('n', 'no')))
            OptionState.__init__(self, options, None, prompt, '?', True)
        else:
            self.mustConfirm = False
        self.parentState = parentState


    def _getInput(self):
        if self.mustConfirm:
            return OptionState._getInput(self)


    def _transition(self, inp):
        if not self.mustConfirm or inp == 'y':
            self.performAction()
        return self.parentState


    def performAction(self):
        '''Custom action, must be overridden by subclasses'''

        raise Exception(
                'Subclasses must override BounceActionState.performAction()')


class AmountInputState(BounceInputState):
    '''BounceInputState which converts user input to int'''

    def _transition(self, inp):
        try:
            inp = int(inp)
        except ValueError:
            print('Error: Invalid number')
            inp = None
        self.parentState.collectedData[self.key] = inp
        return self.parentState


try:
    import dateutil.parser
except ImportError:
    pass

class DateInputState(BounceInputState):
    '''Gets user input and transitions back to the parent state.

    Uses ‘dateutil’ to parse human date strings, if available – otherwise
    the input string is passed unchanged to parentState.collectedData[key].
    '''

    def __init__(self, parentState, key, prompt, default=''):
        if 'dateutil' in sys.modules:
            self.originalPrompt = prompt
            prompt = os.linesep + '\t' + prompt
        BounceInputState.__init__(self, parentState, key, prompt, default)


    def _transition(self, inp):
        result = self.default
        if 'dateutil' in sys.modules:
            try:
                default = datetime.datetime.now().replace(
                        day=1, hour=0, minute=0, second=0, microsecond=0)
                dt_obj = dateutil.parser.parse(inp, default=default)
                result = dt_obj.strftime("%Y-%m-%d")
            except ValueError:
                pass
            print()
            print(self.originalPrompt + ':', result)
        elif inp:
            result = inp

        self.parentState.collectedData[self.key] = result
        return self.parentState
