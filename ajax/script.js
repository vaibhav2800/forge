function addRow() {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200) {
            var table = document.getElementById("mytable");
            table.innerHTML += req.responseText;
        }
    }
    req.open("GET", "new_row.html", true);
    req.send();
}


function editRow(button) {
    var row = button.parentNode.parentNode;
    var cells = row.getElementsByTagName('td');
    var v1 = cells[0].innerHTML;
    var v2 = cells[1].innerHTML;

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200) {
            row.innerHTML = req.responseText;
        }
    }
    edit_url = "edit_row.php?v1=" + encodeURIComponent(v1) +
        "&v2=" + encodeURIComponent(v2);
    req.open("GET", edit_url, true);
    req.send();
}

function saveRow(button) {
    var row = button.parentNode.parentNode;
    var v1 = row.getElementsByTagName('input')[0].value;
    var select = row.getElementsByTagName('select')[0];
    var v2 = select.options[select.selectedIndex].value;

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200) {
            row.innerHTML = req.responseText;
        }
    }
    save_url = "save_row.php?v1=" + encodeURIComponent(v1) +
        "&v2=" + encodeURIComponent(v2);
    req.open("GET", save_url, true);
    req.send();
}
