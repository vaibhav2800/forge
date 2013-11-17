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

import os

def accounts_short(accounts):
    '''Format as index+1), currency, balance, name; empty if no accounts.

    The argument format is defined by util.db.get_all_accounts().
    The only columns accessed (by name) are: currency, balance, name.
    '''

    if not accounts:
        return ''

    # column widths and spacing amounts
    idx_w = len(str(len(accounts)) + ')')
    crr_w = min(10, max(len(acc['currency']) for acc in accounts))
    bal_w = max(len('{:,}'.format(acc['balance'])) for acc in accounts)
    left_sp = 8
    mid_sp = 3
    name_w = 79 - (left_sp + idx_w + crr_w + bal_w + 3 * mid_sp)

    idx_fmt = '{:>' + str(idx_w - 1) + '})'
    crr_fmt = '{:^' + str(crr_w) + '.' + str(crr_w) + '}'
    bal_fmt = '{:>' + str(bal_w) + ',}'
    name_fmt = '{:' + str(name_w) + '.' + str(name_w) + '}'
    fmt_str = left_sp * ' ' + (mid_sp * ' ').join(
            [idx_fmt, crr_fmt, bal_fmt, name_fmt])

    lines = []
    index = 0
    for acc in accounts:
        lines.append(fmt_str.format(
            index+1, acc['currency'], acc['balance'], acc['name']))
        index += 1

    return os.linesep.join(lines)


def categories_list(categories):
    '''Format as index+1), name; empty if no categories.

    The argument format is defined by util.db.get_categories().
    The only columns accessed (by name) is: name.
    '''

    if not categories:
        return ''

    # column widths and spacing amounts
    idx_w = len(str(len(categories)) + ')')
    left_sp = 8
    mid_sp = 2
    name_w = 79 - (left_sp + idx_w + mid_sp)

    idx_fmt = '{:>' + str(idx_w - 1) + '})'
    name_fmt = '{:' + str(name_w) + '.' + str(name_w) + '}'
    fmt_str = left_sp * ' ' + (mid_sp * ' ').join([idx_fmt, name_fmt])

    lines = []
    index = 0
    for categ in categories:
        lines.append(fmt_str.format(index+1, categ['name']))
        index += 1

    return os.linesep.join(lines)
