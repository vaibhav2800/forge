<?php

require_once './db.php';
require_once './accounts_util.php';

const TRANSACTIONS_PER_PAGE = 25;

const SQL_CONDITION_INVOLVE_OPEN_ACCOUNT =
  '(
  CASE WHEN from_account IS NULL THEN 0
  ELSE (SELECT closed FROM accounts WHERE accounts.ID = from_account) = 0 END
  OR
  CASE WHEN to_account IS NULL THEN 0
  ELSE (SELECT closed FROM accounts WHERE accounts.ID = to_account) = 0 END
  )';

/**
 * Returns the HTML for the transaction browser.
 * Transactions not involving an open account are omitted.
 * $for_account shows only transactions for that account; pass -1 to show all
 * accounts.
 * Transactions between $offset and $offset+TRANSACTIONS_PER_PAGE are shown.
 */
function render_transactions_browser($for_account = -1, $offset = 0) {
  $total_rows = transactions_get_count($for_account);
  $total_pages = (int) ($total_rows / TRANSACTIONS_PER_PAGE) +
    ($total_rows % TRANSACTIONS_PER_PAGE === 0 ? 0 : 1);

  $offset = max((int)$offset, 0);
  $offset = min($offset, max($total_rows - 1, 0));
  $offset -= $offset % TRANSACTIONS_PER_PAGE;

  $last_page_offset = max(0, ($total_pages - 1) * TRANSACTIONS_PER_PAGE);
  $next_offset = min($offset + TRANSACTIONS_PER_PAGE, $last_page_offset);
  $prev_offset = max($offset - TRANSACTIONS_PER_PAGE, 0);

  $db = get_db();

  $sql =
    'SELECT ID, date, description, amount, ' .
    'CASE WHEN from_account IS NULL THEN \'Income\' '.
    'WHEN to_account IS NULL THEN \'Payment\' '.
    'ELSE \'Transfer\' END ' .
    'AS transaction_type, '.
    '(SELECT name FROM categories WHERE categories.ID = category) ' .
    'AS category_name, ' .
    '(SELECT name FROM accounts WHERE accounts.ID = from_account) ' .
    'AS from_acc_name, ' .
    '(SELECT name FROM accounts WHERE accounts.ID = to_account) ' .
    'AS to_acc_name, ' .
    '(SELECT currencies.name FROM currencies, accounts ' .
    'WHERE currencies.ID = accounts.currency AND ' .
    '(accounts.ID = from_account OR accounts.ID = to_account)) ' .
    'AS currency_name ' .
    'FROM transactions '.
    'WHERE ' .
    SQL_CONDITION_INVOLVE_OPEN_ACCOUNT .
    ($for_account == -1 ? '' :
      'AND (from_account = :for_account OR to_account = :for_account) ') .
    'ORDER BY DATE(date) DESC ' .
    'LIMIT :limit OFFSET :offset;';

  $stmt = $db->prepare($sql);
  if ($for_account != -1)
    $stmt->bindValue(':for_account', $for_account, SQLITE3_INTEGER);
  $stmt->bindValue(':limit', TRANSACTIONS_PER_PAGE, SQLITE3_INTEGER);
  $stmt->bindValue(':offset', $offset, SQLITE3_INTEGER);

  $results = $stmt->execute();

  $rows_shown = 0;
  $table_contents = '';
  while ($row = $results->fetchArray()) {
    $rows_shown++;
    $table_contents .= render_transaction_row($row);
  }

  $accounts_dropdown =
    '<select onchange="transactionsBrowserReload(' .
      'this.options[this.selectedIndex].value, 1)">' .
    '<option value="-1">All accounts</option>' .
    render_accounts_dropdown_contents($for_account) .
    '</select>';

  //$human_page_end = min($offset + 1 + TRANSACTIONS_PER_PAGE, $total_rows);
  $offsets_dropdown_options = '';
  for ($i = 0; $i <= $last_page_offset; $i += TRANSACTIONS_PER_PAGE) {
    $offsets_dropdown_options .=
      '<option value="' . $i . '"' .
        ($i == $offset ? ' selected="true"' : '') .
      '>' .
      ($i+1) .'–'. min($i + TRANSACTIONS_PER_PAGE, $total_rows) .
      '</option>';
  }

  $offsets_span =
    '<span>' .
    '<button onclick="transactionsBrowserReload(' .
                      $for_account . ', 0)" ' .
      ($offset == 0 ? 'disabled="disabled"' : '') .
      '>' .
      htmlentities('<< first') .
    '</button>' .
    ' ' .
    '<button onclick="transactionsBrowserReload(' .
                      $for_account . ', ' . $prev_offset . ')" ' .
      ($prev_offset == $offset ? 'disabled="disabled"' : '') .
      '>' .
      htmlentities('< prev') .
    '</button>' .
    ' ' .
    '<select id="transactionsBrowserPage" ' .
      'onchange="transactionsBrowserReload(' .
      $for_account . ', this.options[this.selectedIndex].value)">' .
      $offsets_dropdown_options .
    '</select>' .
    ' / ' . $total_rows .
    ' ' .
    '<button onclick="transactionsBrowserReload(' .
                      $for_account . ', ' . $next_offset . ')" ' .
      ($next_offset == $offset ? 'disabled="disabled"' : '') .
      '>' .
      htmlentities('next >') .
    '</button>' .
    ' ' .
    '<button onclick="transactionsBrowserReload(' .
                      $for_account . ', ' . $last_page_offset . ')" ' .
      ($last_page_offset == $offset ? 'disabled="disabled"' : '') .
      '>' .
      htmlentities('last >>') .
    '</button>' .
    '</span>';

  return
    $accounts_dropdown . ' ' .
    $offsets_span .
    '<table>' . $table_contents . '</table>';
}


/*
 * Returns the number of transactions involving $for_account. If $for_account
 * is -1, returns the total number of transactions.
 * Transactions not involving an open account are omitted.
 */
function transactions_get_count($for_account = -1) {
  $sql = 'SELECT COUNT(*) AS count FROM transactions ' .
    'WHERE ' .
    SQL_CONDITION_INVOLVE_OPEN_ACCOUNT .
    ($for_account == -1 ? '' :
      'AND from_account = :for_account OR to_account = :for_account ') .
    ';';
  $db = get_db();
  $stmt = $db->prepare($sql);
  if ($for_account != -1)
    $stmt->bindValue(':for_account', $for_account, SQLITE3_INTEGER);
  $results = $stmt->execute();
  $row = $results->fetchArray();
  return $row['count'];
}


/**
 * Returns a full HTML table row '<tr>..</tr>'.
 * @see render_transaction_row_contents() for the required parameter.
 */
function render_transaction_row($row) {
  return
    '<tr id="transaction_' . $row['ID'] . '" ' .
      'class="'.htmlspecialchars(strtolower($row['transaction_type'])).'">' .
      render_transaction_row_contents($row) .
    '</tr>';
}


/*
 * Returns the contents of an HTML table row (i.e. without '<tr>' and '</tr>').
 * Needs a DB row with 'ID', 'from_account_name', 'to_account_name', 'date',
 * 'description', 'category_name', 'amount', 'currency_name',
 * 'transaction_type'.
 */
function render_transaction_row_contents($row) {
  return
    '<td>' . htmlspecialchars($row['transaction_type']) . '</td>' .
    '<td>' . htmlspecialchars($row['from_acc_name']) . '</td>' .
    '<td>' . htmlspecialchars($row['to_acc_name']) . '</td>' .
    '<td>' . $row['date'] . '</td>' .
    '<td>' . htmlspecialchars($row['description']) . '</td>' .
    '<td>' . htmlspecialchars($row['category_name']) . '</td>' .
    '<td class="amount">' . number_format($row['amount']) . '</td>' .
    '<td>' . htmlspecialchars($row['currency_name']) . '</td>' .
    '<td>' .
      '<button type="button" onclick="editTransactionForm(this)">' .
        'edit' .
      '</button> ' .
      '<button type="button" onclick="deleteTransaction(this)">' .
        'delete' .
      '</button> ' .
      '<span class="viewTransactionErr"></span>' .
    '</td>';
}

?>
