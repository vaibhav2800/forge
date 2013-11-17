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
from collections import OrderedDict
from .basestate import BaseState, OptionState, InputState
from .collect import CollectDataState, BounceActionState, BounceInputState, \
                    AmountInputState, DateInputState
from .mainmenu import MainMenuState
from . import fmt
from util import db


def select_account(accounts, user_input):
    '''Selects an account from the list of Rows, or returns None.

    If the user input is a valid index into the list of accounts, that account
    is returned. Otherwise the input is treated as a substring of an account
    name. If a single account name contains that input, that account is
    returned, else None is returned.
    '''
    if user_input.isnumeric():
        idx = int(user_input) - 1
        if 0 <= idx and idx < len(accounts):
            return accounts[idx]

    substr = user_input.lower()
    matches = [acc for acc in accounts if
            (acc['name'].lower().find(substr) != -1)]

    if len(matches) == 1:
        return matches[0]

    for match in matches:
        if match['name'].lower() == substr:
            return match

    return None


class SelectAccountState(InputState):
    '''Set nextState.selectedAccount and move to nextState.'''

    def __init__(self, nextState, accounts, entryTitle='Select Account'):
        self.nextState = nextState
        self.accounts = accounts
        self.entryTitle = entryTitle
        if self.accounts:
            prompt = 'Account index or part of name [Empty cancels]'
            end = ':'
        else:
            prompt = 'No accounts available. [Hit ENTER to continue]'
            end = ''
        InputState.__init__(self, prompt, end=end, requireNonEmpty=False)


    def getEntryMsg(self):
        title = '{:^79}'.format(self.entryTitle)
        if self.accounts:
            body = fmt.accounts_short(self.accounts)
            return title + os.linesep * 3 + body
        else:
            return title


    def _transition(self, inp):
        if self.accounts and inp:
            self.nextState.selectedAccount = select_account(self.accounts, inp)
            if not self.nextState.selectedAccount:
                print()
                input("Your input didn't uniquely match an account." + \
                        os.linesep + '[Hit ENTER to continue] ')
        else:
            self.nextState.selectedAccount = None

        return self.nextState


def select_category(categories, user_input):
    '''Selects a category from the list of Rows, or returns None.

    If the user input is a valid index into the list of categories,
    that category is returned. Otherwise the input is treated as a substring
    of a category name. If a single category name contains that input,
    that category is returned, else None is returned.
    '''
    if user_input.isnumeric():
        idx = int(user_input) - 1
        if 0 <= idx and idx < len(categories):
            return categories[idx]

    substr = user_input.lower()
    matches = [categ for categ in categories if
            (categ['name'].lower().find(substr) != -1)]

    if len(matches) == 1:
        return matches[0]

    for match in matches:
        if match['name'].lower() == substr:
            return match

    return None


class SelectCategoryState(BounceInputState):
    '''Set nextState.selectedAccount and move to nextState.'''

    def __init__(self, parentState, categories, key):
        self.categories = categories
        if self.categories:
            prompt = os.linesep + \
                    fmt.categories_list(self.categories) + \
                    os.linesep + \
                    ' ' * 8 + 'Category (enter index or part of name)'
        else:
            prompt = 'No categories available.' + os.linesep + \
                    '[Hit ENTER to continue]'
        BounceInputState.__init__(self, parentState, key, prompt)


    def _transition(self, inp):
        categ_ID = None
        if self.categories:
            selected_categ = select_category(self.categories, inp)
            if selected_categ:
                categ_ID = selected_categ['ID']
                print()
                print('Category:', selected_categ['name'])
            else:
                print()
                input("Your input didn't uniquely match a category. " + \
                        '[Hit ENTER to continue]' + os.linesep)

        self.parentState.collectedData[self.key] = categ_ID
        return self.parentState


class AccountMgmtState(OptionState):
    '''Account management state'''

    def __init__(self):
        options = OrderedDict((
            ('c', 'Create New Account'),
            ('q', 'Quit'),
            ))
        OptionState.__init__(self, options, 'q')


    def getEntryMsg(self):
        title = '{:^79}'.format('Account Management')
        active_accounts = db.get_active_accounts()
        if active_accounts:
            body = fmt.accounts_short(active_accounts)
        else:
            body = 'No accounts currently defined'
        return title + os.linesep * 3 + body


    def _transition(self, inp):
        if inp == 'c':
            return AccountCreateCollectState(self)
        else:
            return MainMenuState()


class AccountCreateCollectState(CollectDataState):

    def __init__(self, parentState):
        userDataStates = [
                BounceInputState(self, 'name', 'New Account Name'),
                BounceInputState(self, 'currency', 'Currency'),
                ]
        actionState = AccountCreateActionState(
                self, 'Confirm account creation')
        CollectDataState.__init__(self, parentState,
                userDataStates, actionState)


class AccountCreateActionState(BounceActionState):

    def performAction(self):
        data = self.parentState.collectedData
        db.create_account(**{k:data[k] for k in ['name', 'currency']})
        print('Created new account:', data['name'])


class AccountTransactionState(OptionState):
    '''Asks user for payment, income or transfer. Needs self.selectedAccount.

    SelectAccountState should be used to transition into this state.
    If no account was selected, quietly transitions to main menu.
    Every time the state is entered, it fetches the account from the DB
    because its children are Collect*States that can modify the balance before
    bouncing back to this state.
    '''

    def __init__(self):
        options = OrderedDict((
            ('i', 'Income'),
            ('p', 'Payment'),
            ('t', 'Transfer'),
            ('b', 'Back to main menu'),
            ))
        OptionState.__init__(self, options, prompt='Choose a transaction type')


    def getEntryMsg(self):
        # reload the account balance every time the state is entered
        if self.selectedAccount:
            self.selectedAccount = \
                    db.get_account(self.selectedAccount['ID'])[0]
        if not self.selectedAccount:
            return None
        title = '{:^79}'.format('New Transaction')
        body = fmt.accounts_short([self.selectedAccount])
        return title + os.linesep * 3 + body


    def _getInput(self):
        if not self.selectedAccount:
            return 'b'
        return OptionState._getInput(self)


    def _transition(self, inp):
        if inp == 'i':
            return AccountIncomeCollectState(self, self.selectedAccount)
        elif inp == 'p':
            return AccountPaymentCollectState(self, self.selectedAccount)
        elif inp == 't':
            preTransf = AccountPreTransferState(self, self.selectedAccount)
            return SelectAccountState(preTransf,
                    db.get_accounts_for_transfer(self.selectedAccount['ID']))
        else:
            return MainMenuState()


class AccountIncomeCollectState(CollectDataState):

    def __init__(self, parentState, account):
        userDataStates = [
                DateInputState(self, 'date', 'Date'),
                BounceInputState(self, 'description', 'Description'),
                SelectCategoryState(self, db.get_categories(), 'category'),
                AmountInputState(self, 'amount', 'Amount'),
                ]
        actionState = AccountIncomeActionState(
                self, 'Confirm new income transaction')
        CollectDataState.__init__(self, parentState,
                userDataStates, actionState)
        self.collectedData['to_account'] = account['ID']


class AccountIncomeActionState(BounceActionState):

    def performAction(self):
        data = self.parentState.collectedData
        db.add_income(**{k:data[k] for k in
            ['date', 'description', 'category', 'amount', 'to_account']})
        print('Added new income transaction')


class AccountPaymentCollectState(CollectDataState):

    def __init__(self, parentState, account):
        userDataStates = [
                DateInputState(self, 'date', 'Date'),
                BounceInputState(self, 'description', 'Description'),
                SelectCategoryState(self, db.get_categories(), 'category'),
                AmountInputState(self, 'amount', 'Amount'),
                ]
        actionState = AccountPaymentActionState(
                self, 'Confirm new payment transaction')
        CollectDataState.__init__(self, parentState,
                userDataStates, actionState)
        self.collectedData['from_account'] = account['ID']


class AccountPaymentActionState(BounceActionState):

    def performAction(self):
        data = self.parentState.collectedData
        db.add_payment(**{k:data[k] for k in
            ['date', 'description', 'category', 'amount', 'from_account']})
        print('Added new payment')


class AccountPreTransferState(BaseState):
    '''Checks selectedAccount then moves to TransferCollect or back to parent.

    Should transition to this state using SelectAccountState.
    Checks that SelectAccountState selected an account (the destination) then
    decides to go back to parent or advance to AccountTransferCollectState.
    '''

    def __init__(self, parent, from_account):
        self.parent = parent
        self.from_account = from_account


    def getEntryMsg(self):
        if self.selectedAccount:
            title = '{:^79}'.format('New Transfer Between Accounts')
            body = fmt.accounts_short(
                    [self.from_account, self.selectedAccount])
            return title + os.linesep * 3 + body


    def _getInput(self):
        pass


    def _transition(self, inp):
        if self.selectedAccount:
            return AccountTransferCollectState(self.parent,
                    self.from_account, self.selectedAccount)
        else:
            return self.parent


class AccountTransferCollectState(CollectDataState):

    def __init__(self, parentState, from_account, to_account):
        userDataStates = [
                DateInputState(self, 'date', 'Date'),
                BounceInputState(self, 'description', 'Description'),
                SelectCategoryState(self, db.get_categories(), 'category'),
                AmountInputState(self, 'amount', 'Amount'),
                ]
        actionState = AccountTransferActionState(
                self, 'Confirm new transfer between accounts')
        CollectDataState.__init__(self, parentState, userDataStates,
                actionState)
        self.collectedData['from_account'] = from_account['ID']
        self.collectedData['to_account'] = to_account['ID']


class AccountTransferActionState(BounceActionState):

    def performAction(self):
        data = self.parentState.collectedData
        db.add_transaction(**{k:data[k] for k in
            ['date', 'description', 'category', 'amount',
                'from_account', 'to_account']})
        print('Added new transfer between accounts.')


class CategoryMgmtState(OptionState):
    '''Category management state'''

    def __init__(self):
        options = OrderedDict((
            ('c', 'Create new Category'),
            ('q', 'Quit'),
            ))
        OptionState.__init__(self, options, 'q')


    def getEntryMsg(self):
        title = '{:^79}'.format('Category Management')
        categories = db.get_categories()
        if categories:
            body = fmt.categories_list(categories)
        else:
            body = 'No categories currently defined'
        return title + os.linesep * 3 + body


    def _transition(self, inp):
        if inp == 'c':
            return CategoryCreateCollectState(self)
        else:
            return MainMenuState()


class CategoryCreateCollectState(CollectDataState):

    def __init__(self, parentState):
        userDataStates = [
                BounceInputState(self, 'name', 'New Category Name'),
                ]
        actionState = CategoryCreateActionState(
                self, 'Confirm category creation')
        CollectDataState.__init__(self, parentState,
                userDataStates, actionState)


class CategoryCreateActionState(BounceActionState):

    def performAction(self):
        data = self.parentState.collectedData
        db.create_category(**{k:data[k] for k in ['name']})
        print('Created new category:', data['name'])
