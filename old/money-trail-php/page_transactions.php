<?php
require_once './accounts_util.php';
require_once './categories_util.php';
require_once './transactions_util.php';
?>

<div class="newItemArea newTransactionArea">
  <p id="newTransactionPreForm">
    <label for="transAccountPreselect">Account:</label>
    <select id="transAccountPreselect">
      <?php
      echo render_accounts_dropdown_contents();
      ?>
    </select>
    <button type="button" onclick="newTransactionForm('Payment')">
      Payment
    </button>
    <button type="button" onclick="newTransactionForm('Income')">
      Income
    </button>
    <button type="button" onclick="newTransactionForm('Transfer')">
      Transfer
    </button>
    <span id="newTransactionPreFormErr"></span>
  </p>

  <div id="newTransactionForm" hidden="hidden">
    <table>
      <tr>
        <td>
          <label>Type</label>
        </td>
        <td>
          <label for="newTransactionFromAcc">From</label>
        </td>
        <td>
          <label for="newTransactionToAcc">To</label>
        </td>
        <td>
          <label for="newTransactionDate">Date</label>
        </td>
        <td>
          <label for="newTransactionDescr">Description</label>
        </td>
        <td>
          <label for="newTransactionCateg">Category</label>
        </td>
        <td>
          <label for="newTransactionAmount">Amount</label>
        </td>
        <td>
          <label>Currency</label>
        </td>
      </tr>

      <tr id="newTransactionFormMainRow">
        <td>
          <label id="newTransactionType"></label>
        </td>
        <td>
          <select id="newTransactionFromAcc"></select>
        </td>
        <td>
          <select id="newTransactionToAcc"></select>
        </td>
        <td>
          <input id="newTransactionDate" class="date" type="text" size="10"
            onkeydown="transCheckDate(this, false);newTransactionKeyDown(event);"
            onfocus="transCheckDate(this, true)"
            onblur="transCheckDate(this, true)"
          />
          <br />
          <label class="parsedDate" for="newTransactionDate"></label>
        </td>
        <td>
          <input id="newTransactionDescr" type="text"
            onkeydown="newTransactionKeyDown(event)" />
        </td>
        <td>
          <select id="newTransactionCateg">
            <?php
            echo render_category_dropdown_contents();
            ?>
          </select>
        </td>
        <td>
          <input id="newTransactionAmount" class="amount" type="text" size="5"
            onkeydown="newTransactionKeyDown(event)" />
        </td>
        <td>
          <label id="newTransactionCurrency"></label>
        </td>
      </tr>

      <tr>
        <td colspan="8">
          <button type="button" onclick="newTransactionSubmit()">
            Add Transaction
          </button>
          <button type="button" onclick="newTransactionCancel()">
            Cancel
          </button>
          <span id="newTransactionErr"></span>
        </td>
      </tr>
    </table>
  </div>
</div>

<!-- This outer, unstyled div takes up the whole page width preventing
newItemArea and existingItemsArea (which have display: inline-block;) from
getting put side by side. -->
<div>
  <div class="existingItemsArea" id="transactions_browser">
    <?php
    echo render_transactions_browser();
    ?>
  </div>
</div>
