function newCategoryForm() {
    document.getElementById('newCategoryPreForm').hidden = true;
    document.getElementById('newCategoryForm').hidden = false;
    document.getElementById('newCategoryName').focus();
}


function newCategoryCancel() {
    // first lose focus, otherwise Firefox doesn't change the value
    document.getElementById('newCategoryName').blur();
    document.getElementById('newCategoryName').value = '';
    document.getElementById('newCategoryError').innerHTML = '';
    document.getElementById('newCategoryForm').hidden = true;
    document.getElementById('newCategoryPreForm').hidden = false;
}


function newCategorySubmit() {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                loadPage('page_categories.php');
            } else {
                document.getElementById('newCategoryError').innerHTML =
                    'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'categories_add.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    var name = document.getElementById('newCategoryName').value;
    req.send('name=' + encodeURIComponent(name));
}


function newCategoryKeyDown(e) {
    if (e.keyCode == 13)
        newCategorySubmit();
    else if (e.keyCode == 27)
        newCategoryCancel();
}


function editCategoryForm(btn) {
    var view_tr = btn.parentNode.parentNode;
    var name = view_tr.getElementsByTagName('td')[0].textContent;

    var edit_id = 'edit_' + view_tr.id;
    var edit_tr_html =
        '<tr id="' + edit_id + '">' +
        '<td colspan="2">' +
        '<input type="text" onkeydown="editCategoryKeyDown(event)" /> ' +
        '<button type="button" class="btn-save" ' +
                'onclick="editCategorySubmit(this)">' +
            'Save' +
        '</button> ' +
        '<button type="button" class="btn-cancel" ' +
                'onclick="editCategoryCancel(this)">' +
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


function editCategoryCancel(btn) {
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


function editCategorySubmit(btn) {
    var edit_tr = btn.parentNode.parentNode;
    var err_span = edit_tr.getElementsByTagName('span')[0];
    var name = edit_tr.getElementsByTagName('input')[0].value;

    var id = edit_tr.id;
    var prefix = "edit_category_";
    if (id.substring(0, prefix.length) != prefix) {
        err_span.textContent = "internal error: bad HTML table row ID";
        return;
    }
    id = id.substring(prefix.length);

    var view_tr = document.getElementById('category_' + id);

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                loadPage('page_categories.php');
            } else {
                err_span.innerHTML = 'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'categories_update.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('id=' + encodeURIComponent(id) +
            '&name=' + encodeURIComponent(name));
}


function editCategoryKeyDown(e) {
    var tr = e.target.parentNode.parentNode;

    if (e.keyCode == 13)
        tr.getElementsByClassName('btn-save')[0].click();
    else if (e.keyCode == 27)
        tr.getElementsByClassName('btn-cancel')[0].click();
}


function deleteCategory(btn) {
    var tr = btn.parentNode.parentNode;
    var err_span = tr.getElementsByTagName('span')[0];
    var id = tr.id;

    var prefix = "category_";
    if (id.substring(0, prefix.length) != prefix) {
        err_span.textContent = "internal error: bad HTML table row ID";
        return;
    }
    id = id.substring(prefix.length);

    var name = tr.getElementsByTagName('td')[0].textContent;

    if (!confirm('This will delete category ' + name + '. Proceed?'))
        return;

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            if (req.status == 200) {
                loadPage('page_categories.php');
            } else {
                err_span.innerHTML = 'error: ' + req.responseText;
            }
        }
    }

    req.open('POST', 'categories_delete.php', true);
    req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    req.send('id=' + encodeURIComponent(id));
}
