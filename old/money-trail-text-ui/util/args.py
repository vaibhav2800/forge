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

import argparse

def get_args_or_exit():
    '''Get valid args as a dictionary or exit'''

    parser = argparse.ArgumentParser(description='Follow the money trail')
    parser.add_argument('dbfile',
            help='sqlite3 file, will be created if it does not exist')

    group = parser.add_mutually_exclusive_group()
    group.add_argument('-r', '--run', metavar='FILE',
            help='run commands in %(metavar)s')

    parser.add_argument('-d', '--dump', metavar='FILE',
            help='''dump database in SQL text format to %(metavar)s.
            If %(metavar)s contains the string ‘[TIME]’, it will be replaced
            with the current timestamp in the format ‘YYYY-MM-DDTHH:MM:SS’''')

    args = parser.parse_args()
    return args
