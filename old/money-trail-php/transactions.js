function newTransactionForm(type) {
    var err_span = document.getElementById('newTransactionPreFormErr');

    var select = document.getElementById('transAccountPreselect');
    if (select.selectedIndex == -1) {
        err_span.textContent = 'You must first create an account';
        return;
    }
    var account_id = select.options[select.selectedIndex].value;

    var req = new XMLHttpRequest();
    var url = 'accounts_dropdown_contents.php?id=' +
        encodeURIComponent(account_id);
    req.open('GET', url, false);
    req.send();
    if (req.status != 200) {
        err_span.innerHTML = 'error: ' + req.responseText;
        return;
    }

    var sel_from_acc = document.getElementById('newTransactionFromAcc');
    var sel_to_acc = document.getElementById('newTransactionToAcc');

    sel_from_acc.innerHTML = sel_to_acc.innerHTML = '';
    sel_from_acc.disabled = sel_to_acc.disabled = true;

    if (type == 'Payment') {
        sel_from_acc.innerHTML = req.responseText;
        sel_from_acc.disabled = false;
    } else if (type == 'Income') {
        sel_to_acc.innerHTML = req.responseText;
        sel_to_acc.disabled = false;
    } else if (type == 'Transfer') {
        sel_from_acc.innerHTML = req.responseText;

        req = new XMLHttpRequest();
        url = 'accounts_dropdown_contents.php?id=' +
            encodeURIComponent(account_id) + '&transfer_from=' +
            encodeURIComponent(account_id);
        req.open('GET', url, false);
        req.send();
        if (req.status != 200) {
            err_span.innerHTML = 'error: ' + req.responseText;
            return;
        }

        sel_to_acc.innerHTML = req.responseText;
        sel_to_acc.disabled = false;
    } else {
        err_span.textContent = 'internal error: unknown transaction type';
        return;
    }

    req = new XMLHttpRequest();
    url = 'account_currency.php?id=' + encodeURIComponent(account_id);
    req.open('GET', url, false);
    req.send();
    if (req.status != 200) {
        err_span.innerHTML = 'error: ' + req.responseText;
        return;
    }
    document.getElementById('newTransactionCurrency').textContent =
        req.responseText;

    main_tr = document.getElementById('newTransactionFormMainRow');
    main_tr.classList.remove('payment');
    main_tr.classList.remove('income');
    main_tr.classList.remove('transaction');
    main_tr.classList.add(type.toLowerCase());

    document.getElementById('newTransactionType').textContent = type;
    document.getElementById('newTransactionDate').value = '';
    document.getElementById('newTransactionDescr').value = '';
    document.getElementById('newTransactionAmount').value = '';
    document.getElementById('newTransactionErr').textContent = '';
    document.getElementById('newTransactionForm').hidden = false;
    document.getElementById('newTransactionDate').focus();

    document.getElementById('newTransactionPreFormErr').textContent = '';
    document.getElementById('newTransactionPreForm').hidden = true;
}


function newTransactionCancel() {
    document.getElementById('newTransactionForm').hidden = true;
    document.getElementById('newTransactionPreForm').hidden = false;
}


function newTransactionSubmit() {
    var err_span = document.getElementById('newTransactionErr');
    var sel_from_acc = document.getElementById('newTransactionFromAcc');
    var sel_to_acc = document.getElementById('newTransactionToAcc');

    var from_acc = to_acc = 'NULL';
    if (sel_from_acc.selectedIndex != -1)
        from_acc = sel_from_acc.options[sel_from_acc.selectedIndex].value;
    if (sel_to_acc.selectedIndex != -1)
        to_acc = sel_to_acc.options[sel_to_acc.selectedIndex].value;

    var date = document.getElementById('newTransactionDate').value;
    var descr = document.getElementById('newTransactionDescr').value;
    var amount = document.getElementById('newTransactionAmount').value;

    var categ = '';
    var sel_categ = document.getElementById('newTransactionCateg');
    if (sel_categ.selectedIndex != -1)
        categ = sel_categ.options[sel_categ.selectedIndex].value;

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                document.getElementById('newTransactionForm').hidden = true;
                document.getElementById('newTransactionPreForm').hidden = false;
                transactionsBrowserReload(-1, 1);
            } else {
                err_span.innerHTML = 'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'transactions_add.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('from_acc=' + encodeURIComponent(from_acc) +
            '&to_acc=' + encodeURIComponent(to_acc) +
            '&date=' + encodeURIComponent(date) +
            '&descr=' + encodeURIComponent(descr) +
            '&amount=' + encodeURIComponent(amount) +
            '&categ=' + encodeURIComponent(categ));
}


function newTransactionKeyDown(e) {
    if (e.keyCode == 13)
        newTransactionSubmit();
    else if (e.keyCode == 27)
        newTransactionCancel();
}


var date_timeout = 100;
var date_timer;
var date_timer_pending = false;


function transAjaxDate(input) {
    var our_timer = date_timer;
    var lbl = input.parentNode.getElementsByTagName('label')[0];

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (date_timer != our_timer)
            // another timer got started after us; in case our Ajax call
            // completed later, our data is older and must not overwrite
            return;

        if (req.readyState != 4)
            return;

        lbl.textContent = req.responseText;
    }
    var url = 'parse_date.php?date=' + encodeURIComponent(input.value);
    req.open('GET', url, true);
    req.send();

    date_timer_pending = false;
}


function transCheckDate(input, instantly) {
    if (date_timer_pending)
        // timer has already been set, hasn't fired yet
        return;

    date_timer = setTimeout(
            function() {transAjaxDate(input);},
            instantly ? 0 : date_timeout);
    date_timer_pending = true;
}


function transactionsBrowserReload(for_account, offset) {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            document.getElementById('transactions_browser').innerHTML =
                req.responseText;
        }
    }
    var url = 'transactions_browser.php?for_account=' +
        encodeURIComponent(for_account) + '&offset=' +
        encodeURIComponent(offset);
    req.open('GET', url, true);
    req.send();
}


function deleteTransaction(btn) {
    var tr = btn.parentNode.parentNode;
    var err_span = tr.getElementsByClassName('viewTransactionErr')[0];
    var id = tr.id;

    var prefix = "transaction_";
    if (id.substring(0, prefix.length) != prefix) {
        err_span.textContent = "internal error: bad HTML table row ID";
        return;
    }
    id = id.substring(prefix.length);

    if (!confirm('Delete transaction. Proceed?'))
        return;

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                var sel = document.getElementById('transactionsBrowserPage');
                sel.onchange();
            } else {
                err_span.innerHTML = 'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'transactions_delete.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('id=' + encodeURIComponent(id));
}


function editTransactionForm(btn) {
    var view_tr = btn.parentNode.parentNode;
    var err_span = view_tr.getElementsByClassName('viewTransactionErr')[0];
    var id = view_tr.id;

    var prefix = "transaction_";
    if (id.substring(0, prefix.length) != prefix) {
        err_span.textContent = "internal error: bad HTML table row ID";
        return;
    }
    id = id.substring(prefix.length);

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState != 4)
            return;
        if (req.status != 200) {
            err_span.innerHTML = 'error: ' + req.responseText;
            return;
        }

        view_tr.insertAdjacentHTML('afterEnd', req.responseText);
        view_tr.hidden = true;
        edit_id = 'edit_' + view_tr.id;
        document.getElementById(edit_id).
            getElementsByClassName('date')[0].focus();
    }

    req.open('GET', 'transactions_edit.php?id='+encodeURIComponent(id), true);
    req.send();
}


function editTransactionCancel(btn) {
    var edit_tr = btn.parentNode.parentNode;
    var edit_id = edit_tr.id;
    edit_tr.parentNode.removeChild(edit_tr);

    var prefix = "edit_";
    if (edit_id.substring(0, prefix.length) == prefix) {
        var view_id = edit_id.substring(prefix.length);
        var view_tr = document.getElementById(view_id);
        view_tr.hidden = false;
    }
}


function editTransactionSubmit(btn) {
    var edit_tr = btn.parentNode.parentNode;
    var err_span = edit_tr.getElementsByClassName('editTransactionErr')[0];
    var date = edit_tr.getElementsByClassName('date')[0].value;
    var descr =
        edit_tr.getElementsByClassName('editTransactionDescr')[0].value;
    var amount =
        edit_tr.getElementsByClassName('amount')[0].value;
    var categ_sel =
        edit_tr.getElementsByClassName('editTransactionCategory')[0];
    var categ = categ_sel.options[categ_sel.selectedIndex].value;


    var id = edit_tr.id;
    var prefix = "edit_transaction_";
    if (id.substring(0, prefix.length) != prefix) {
        err_span.textContent = "internal error: bad HTML table row ID";
        return;
    }
    id = id.substring(prefix.length);

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                var sel = document.getElementById('transactionsBrowserPage');
                sel.onchange();
            } else {
                err_span.innerHTML = 'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'transactions_update.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('id=' + encodeURIComponent(id) +
            '&date=' + encodeURIComponent(date) +
            '&description=' + encodeURIComponent(descr) +
            '&amount=' + encodeURIComponent(amount) +
            '&category=' + encodeURIComponent(categ));
}


function editTransactionKeyDown(e) {
    var tr = e.target.parentNode.parentNode;

    if (e.keyCode == 13)
        tr.getElementsByClassName('btn-save')[0].click();
    else if (e.keyCode == 27)
        tr.getElementsByClassName('btn-cancel')[0].click();
}
