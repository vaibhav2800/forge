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

from collections import OrderedDict
from .basestate import BaseState, OptionState
from util import db

class ExitState(BaseState):
    '''Signals the end of the textui transitions, provides no functionality.

    Return an ExitState object from getNextState() to exit from the textui.'''
    pass


class MainMenuState(OptionState):
    '''The main menu (first screen) of the textui.'''

    def __init__(self):
        options = OrderedDict((
            ('a', 'Account Management'),
            ('c', 'Category Management'),
            ('t', 'Make Transactions'),
            ('q', 'Quit'),
            ))
        OptionState.__init__(self, options)


    def getEntryMsg(self):
        return '{:^79}'.format('Welcome to Money-Trail!')


    def _transition(self, inp):
        if inp == 'a':
            return AccountMgmtState()
        elif inp == 'c':
            return CategoryMgmtState()
        elif inp == 't':
            accTransactionState = AccountTransactionState()
            return SelectAccountState(accTransactionState,
                    db.get_active_accounts())
        else:
            return ExitState()


from .account import AccountMgmtState
from .account import CategoryMgmtState
from .account import SelectAccountState
from .account import AccountTransactionState
