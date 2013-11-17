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
import os

# sqlite3.Row allows accessing DB results by (case insensitive) column name

conn = cursor = None

def connect(dbfile):
    '''Connects to specified dbfile, must be called first'''
    global conn, cursor
    conn = sqlite3.connect(dbfile)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('PRAGMA foreign_keys = ON;')
    cursor.fetchall()

def commit():
    '''Commits (saves) your changes'''
    conn.commit()

def disconnect():
    '''Commits and disconnects from the dbfile'''
    commit()
    cursor.close()
    conn.close()


def executescript(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        contents = f.read()
        cursor.executescript(contents)
        cursor.fetchall()
        commit()


def dumptofile(filename):
    if os.path.exists(filename):
        warn = 'File ' + filename + ' exists! Overwrite? [y/n] '
        inp = input(warn).lower()
        while inp != 'y' and inp != 'n':
            inp = input(warn).lower()
        if inp != 'y':
            return

    with open(filename, 'w', encoding='utf-8') as f:
        f.write('PRAGMA encoding = "UTF-8";\n')
        f.write('PRAGMA foreign_keys = on;\n')
        for line in conn.iterdump():
            f.write(line)
            f.write('\n')


def assert_kwargs(expected_keys_set, kw_args_dict):
    '''Raises an AssertionError if expected_keys_set != kw_args_dict.keys()'''
    assert expected_keys_set == kw_args_dict.keys(), \
            'Incorrect keyword args supplied, expected {} got {}'.format(
                    expected_keys_set, set(kw_args_dict.keys()))


def create_account(**args):
    '''Creates a new account; see below for required keyword args.

    Keyword args: name, currency.'''

    assert_kwargs({'name', 'currency'}, args)
    sql = 'INSERT INTO accounts(name, currency) VALUES(:name, :currency);'
    cursor.execute(sql, args)


def _sql_accounts(where_clause=None):
    '''Construct SQL query string for accounts with the specified WHERE clause.

    Should not be called from outside this module.
    Columns are: id, name, currency, balance, closed.
    '''

    return '''SELECT ID, name, currency,
            (SELECT ifnull(SUM(amount), 0) FROM transactions
                WHERE to_account = accounts.ID)
            -
            (SELECT ifnull(SUM(amount), 0) FROM transactions
                WHERE from_account = accounts.ID)
            as balance,
            closed
            FROM accounts
            {}
            ORDER BY closed ASC, name ASC;
            '''.format('WHERE ' + where_clause if where_clause else '')


def get_all_accounts():
    '''All, including closed accounts, as a list of rows.

    Keys are defined by _sql_accounts()
    '''

    sql = _sql_accounts()
    cursor.execute(sql)
    return cursor.fetchall()


def get_active_accounts():
    '''Not closed accounts, as a list of rows.

    Keys are defined by _sql_accounts()
    '''

    sql = _sql_accounts('closed = 0')
    cursor.execute(sql)
    return cursor.fetchall()


def get_account(ID):
    '''Returns account with ID, as a list of rows (1 or 0).

    Keys are defined by _sql_accounts()
    '''

    sql = _sql_accounts('ID = :id')
    cursor.execute(sql, {'id':ID})
    return cursor.fetchall()


def get_accounts_for_transfer(ID):
    '''Returns active accounts with same currency as ID, excluding ID itself.

    Keys are defined by _sql_accounts()
    '''

    sql = _sql_accounts('''closed = 0 AND ID != :id
            AND currency = (SELECT currency FROM accounts where ID = :id)''')
    cursor.execute(sql, {'id':ID})
    return cursor.fetchall()


def create_category(**args):
    '''Creates a new category. Keyword arg: name.'''

    assert_kwargs({'name'}, args)
    sql = 'INSERT INTO categories(name) VALUES(:name);'
    cursor.execute(sql, args)


def get_categories():
    '''Categories as a list of rows. Columns: id, name.'''

    sql = 'SELECT ID, name FROM categories ORDER BY name ASC;'
    cursor.execute(sql)
    return cursor.fetchall()


def add_transaction(**args):
    '''Adds a new transaction; see below for required keyword args.

    Keyword args:   date, description, category, amount,
                    from_account, to_account.
    '''

    expected = {'date', 'description', 'category', 'amount',
                'from_account', 'to_account'}
    assert_kwargs(expected, args)

    from_account, to_account = args['from_account'], args['to_account']
    assert from_account != to_account, \
            'Cannot transfer from an account to itself'
    if from_account != None and to_account != None:
        sql = '''SELECT COUNT(*) FROM accounts
                WHERE ID = :from_account OR ID = :to_account
                GROUP BY currency;'''
        cursor.execute(sql, args)
        assert len(cursor.fetchall()) == 1, \
                'Accounts must have the same currency'

    sql = '''INSERT INTO transactions(
            date, description, category, amount, from_account, to_account)
            values(:date, :description, :category, :amount,
            :from_account, :to_account);'''
    cursor.execute(sql, args)


def add_income(**args):
    '''Adds a new income transaction.

    Keyword args are: date, description, category, amount, to_account.
    '''

    expected = {'date', 'description', 'category', 'amount', 'to_account'}
    assert_kwargs(expected, args)
    args['from_account'] = None
    add_transaction(**args)


def add_payment(**args):
    '''Adds a new payment transaction.

    Keyword args are: date, description, category, amount, from_account.
    '''

    expected = {'date', 'description', 'category', 'amount', 'from_account'}
    assert_kwargs(expected, args)
    args['to_account'] = None
    add_transaction(**args)


def get_all_transactions():
    sql = 'SELECT * FROM transactions;'
    cursor.execute(sql)
    return cursor.fetchall()
