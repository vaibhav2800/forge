#! /usr/bin/env python3

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

import os, sys, time

if __name__ == '__main__':
    sys.path.append(os.path.join(os.path.dirname(sys.argv[0]), 'lib'))

from util import db
from util.textui import driver
import util.args

if __name__ == '__main__':
    args = util.args.get_args_or_exit()
    db.connect(args.dbfile)

    if args.run:
        db.executescript(args.run)

    # idempotent statements, e.g. CREATE TABLE IF NOT EXISTS
    db.executescript(os.path.join(
        os.path.dirname(sys.argv[0]), 'create-tables.sql'))

    driver.run()
    db.commit()

    if args.dump:
        db.dumptofile(args.dump.replace(
            '[TIME]', time.strftime('%Y-%m-%dT%H:%M:%S')))

    db.disconnect()
