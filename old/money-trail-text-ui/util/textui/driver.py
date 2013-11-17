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

import sqlite3
import traceback
from .mainmenu import MainMenuState, ExitState

# get readline functionality
import readline

def run():
    '''Starts the textui.'''

    state = MainMenuState()
    while not isinstance(state, ExitState):
        try:
            state = state.getNextState()
        except sqlite3.Error:
            print()
            traceback.print_exc(0)
            print()
            input('[Hit ENTER to continue] ')
            state = MainMenuState()
