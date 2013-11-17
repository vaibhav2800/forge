<?php
require_once './db.php';
require_once './currencies_util.php';

$db = get_db();
$results =
  $db->query('SELECT ID, name FROM currencies ORDER BY name ASC;');
?>

<div class="newItemArea newCurrencyArea">
  <p id="newCurrencyPreForm">
    <button type="button" onclick="newCurrencyForm()">Add New Currency</button>
  </p>

  <p id="newCurrencyForm" hidden="hidden">
    <label for="newCurrencyName">New Currency:</label>
    <input type="text" id="newCurrencyName"
      onkeydown="newCurrencyKeyDown(event)" />
    <button type="button" onclick="newCurrencySubmit()">Add</button>
    <button type="button" onclick="newCurrencyCancel()">Cancel</button>
    <span id="newCurrencyError"></span>
  </p>
</div>

<!-- This outer, unstyled div takes up the whole page width preventing
newItemArea and existingItemsArea (which have display: inline-block;) from
getting put side by side. -->
<div>
  <div class="existingItemsArea">
    <table id="currencyTable">
      <?php
      while ($row = $results->fetchArray()) {
        echo render_currency_row($row);
      }
      ?>
    </table>
  </div>
</div>
