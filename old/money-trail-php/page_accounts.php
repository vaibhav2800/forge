<?php
require_once './db.php';
require_once './currencies_util.php';
require_once './accounts_util.php';

$db = get_db();
$results_open = $db->query(get_account_data_query_string(true));
?>

<div class="newItemArea newAccountArea">
  <p id="newAccountPreForm">
    <button type="button" onclick="newAccountForm()">Add New Account</button>
  </p>

  <p id="newAccountForm" hidden="hidden">
    <label for="newAccountName">Name:</label>
    <input type="text" id="newAccountName"
      onkeydown="newAccountKeyDown(event)" />

    <label for="newAccountCurrency">Currency:</label>
    <select id="newAccountCurrency">
      <?php
      echo render_currency_dropdown_contents(-1);
      ?>
    </select>

    <button type="button" onclick="newAccountSubmit()">Add</button>
    <button type="button" onclick="newAccountCancel()">Cancel</button>
    <span id="newAccountError"></span>
  </p>
</div>

<!-- This outer, unstyled div takes up the whole page width preventing
newItemArea and existingItemsArea (which have display: inline-block;) from
getting put side by side. -->
<div>
  <div class="existingItemsArea">
    <table id="openAccountsTable">
      <?php
      while ($row = $results_open->fetchArray()) {
        echo render_account_row($row);
      }
      ?>
    </table>

    <?php
      $closed_num = get_account_count(false);
      if ($closed_num > 0) {
        $results_closed = $db->query(get_account_data_query_string(false));
    ?>
    <input type="checkbox" id="closedAccountsChk"
      onclick="showHideClosedAccounts()" />
    <label for="closedAccountsChk">
      Show <?php echo $closed_num ?>
      closed account<?php if ($closed_num > 1) echo 's';?>
    </label>
    <table id="closedAccountsTable" hidden="hidden">
      <?php
      while ($row = $results_closed->fetchArray()) {
        echo render_account_row($row);
      }
      ?>
    </table>
    <?php
      }
    ?>
  </div>
</div>
