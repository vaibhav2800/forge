function newAccountForm() {
    document.getElementById('newAccountPreForm').hidden = true;
    document.getElementById('newAccountForm').hidden = false;
    document.getElementById('newAccountName').focus();
}


function newAccountCancel() {
    // first lose focus, otherwise Firefox doesn't change the value
    document.getElementById('newAccountName').blur();
    document.getElementById('newAccountName').value = '';
    document.getElementById('newAccountCurrency').selectedIndex = 0;
    document.getElementById('newAccountError').innerHTML = '';
    document.getElementById('newAccountForm').hidden = true;
    document.getElementById('newAccountPreForm').hidden = false;
}


function newAccountSubmit() {
    var name = document.getElementById('newAccountName').value;
    var select = document.getElementById('newAccountCurrency');
    if (select.selectedIndex == -1) {
        document.getElementById('newAccountError').innerHTML =
            'error: you must first add a currency';
        return;
    }
    var currency = select.options[select.selectedIndex].value;

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                loadPage('page_accounts.php');
            } else {
                document.getElementById('newAccountError').innerHTML =
                    'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'accounts_add.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('name=' + encodeURIComponent(name) +
            '&currency=' + encodeURIComponent(currency));
}


function newAccountKeyDown(e) {
    if (e.keyCode == 13)
        newAccountSubmit();
    else if (e.keyCode == 27)
        newAccountCancel();
}


function editAccountForm(btn) {
    var view_tr = btn.parentNode.parentNode;
    var err_span = view_tr.getElementsByTagName('span')[0];
    var name = view_tr.getElementsByTagName('td')[0].textContent;

    var id = view_tr.id;
    var prefix = "account_";
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
            err_span.innerHTML = 'internal error retrieving edit dropdown';
            return;
        }

        var edit_id = 'edit_' + view_tr.id;
        var edit_tr_html =
            '<tr id="' + edit_id + '">' +
            '<td colspan="4">' +
            '<input type="text" onkeydown="editAccountKeyDown(event)" /> ' +
            // responseText is <select>..</select>
            req.responseText + ' ' +
            '<button type="button" class="btn-save" ' +
                    'onclick="editAccountSubmit(this)">' +
                'Save' +
            '</button> ' +
            '<button type="button" class="btn-cancel" ' +
                    'onclick="editAccountCancel(this)">' +
                'Cancel' +
            '</button> ' +
            '<span></span>' +
            '</td>' +
            '</tr>';

        view_tr.insertAdjacentHTML('afterEnd', edit_tr_html);
        view_tr.hidden = true;

        var edit_tr = document.getElementById(edit_id);
        var input = edit_tr.getElementsByTagName('input')[0];
        input.value = name;
        input.focus();
    }

    var url = 'currencies_dropdown.php?for_account=' + encodeURIComponent(id);
    req.open('GET', url, true);
    req.send();
}


function editAccountCancel(btn) {
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


function editAccountSubmit(btn) {
    var edit_tr = btn.parentNode.parentNode;
    var err_span = edit_tr.getElementsByTagName('span')[0];
    var name = edit_tr.getElementsByTagName('input')[0].value;
    var select = edit_tr.getElementsByTagName('select')[0];
    var currency = select.options[select.selectedIndex].value;

    var id = edit_tr.id;
    var prefix = "edit_account_";
    if (id.substring(0, prefix.length) != prefix) {
        err_span.textContent = "internal error: bad HTML table row ID";
        return;
    }
    id = id.substring(prefix.length);

    var view_tr = document.getElementById('account_' + id);

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                loadPage('page_accounts.php');
            } else {
                err_span.innerHTML = 'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'accounts_update.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('id=' + encodeURIComponent(id) +
            '&name=' + encodeURIComponent(name) +
            '&currency=' + encodeURIComponent(currency));
}


function editAccountKeyDown(e) {
    var tr = e.target.parentNode.parentNode;

    if (e.keyCode == 13)
        tr.getElementsByClassName('btn-save')[0].click();
    else if (e.keyCode == 27)
        tr.getElementsByClassName('btn-cancel')[0].click();
}


function deleteAccount(btn) {
    var tr = btn.parentNode.parentNode;
    var err_span = tr.getElementsByTagName('span')[0];
    var id = tr.id;

    var prefix = "account_";
    if (id.substring(0, prefix.length) != prefix) {
        err_span.textContent = "internal error: bad HTML table row ID";
        return;
    }
    id = id.substring(prefix.length);

    var name = tr.getElementsByTagName('td')[0].textContent;

    if (!confirm('This will delete account ' + name + '. Proceed?'))
        return;

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                loadPage('page_accounts.php');
            } else {
                err_span.innerHTML = 'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'accounts_delete.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('id=' + encodeURIComponent(id));
}


function closeOrOpenAccount(btn, close) {
    var tr = btn.parentNode.parentNode;
    var err_span = tr.getElementsByTagName('span')[0];
    var id = tr.id;

    var prefix = "account_";
    if (id.substring(0, prefix.length) != prefix) {
        err_span.textContent = "internal error: bad HTML table row ID";
        return;
    }
    id = id.substring(prefix.length);

    var name = tr.getElementsByTagName('td')[0].textContent;

    if (!confirm('This will ' + (close ? 'close' : 'open') +
                ' account ' + name + '. Proceed?'))
        return;

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                loadPage('page_accounts.php');
            } else {
                err_span.innerHTML = 'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'accounts_close.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('id=' + encodeURIComponent(id) +
            '&close=' + encodeURIComponent(close));
}


function showHideClosedAccounts() {
    document.getElementById('closedAccountsTable').hidden =
        !document.getElementById('closedAccountsChk').checked;
}
