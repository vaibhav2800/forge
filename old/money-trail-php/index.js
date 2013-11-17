function loadPage(url) {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4) {
            var container = document.getElementById('mainContainer');
            container.innerHTML = req.responseText;
        }
    }
    req.open('GET', url, true);
    req.send();
}
