<?php
/**
 * GET parameter: id.
 * Returns an HTML table row <tr>..</tr> for editing the transaction.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';
require_once './categories_util.php';

$id = (int) GET_key_or_exit('id');

$db = get_db();

$sql =
  'SELECT ID, date, description, amount, ' .
  'CASE WHEN from_account IS NULL THEN \'Income\' '.
  'WHEN to_account IS NULL THEN \'Payment\' '.
  'ELSE \'Transfer\' END ' .
  'AS transaction_type, '.
  'category, ' .
  '(SELECT name FROM accounts WHERE accounts.ID = from_account) ' .
  'AS from_acc_name, ' .
  '(SELECT name FROM accounts WHERE accounts.ID = to_account) ' .
  'AS to_acc_name, ' .
  '(SELECT currencies.name FROM currencies, accounts ' .
  'WHERE currencies.ID = accounts.currency AND ' .
  '(accounts.ID = from_account OR accounts.ID = to_account)) ' .
  'AS currency_name ' .
  'FROM transactions ' .
  'WHERE ID = :id ';

$stmt = $db->prepare($sql);
$stmt->bindValue(':id', $id, SQLITE3_INTEGER);
$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());
$row = $results->fetchArray();
exit_if(!$row, 'not found');

echo
  '<tr id="edit_transaction_' . $id . '" ' .
    'class="' . htmlspecialchars(strtolower($row['transaction_type'])) . '">' .
  '<td>' . htmlspecialchars($row['transaction_type']) . '</td>' .
  '<td>' . htmlspecialchars($row['from_acc_name']) . '</td>' .
  '<td>' . htmlspecialchars($row['to_acc_name']) . '</td>' .
  '<td>' .
    '<input class="date" type="text" size="10" ' .
      'onkeydown="transCheckDate(this, false);editTransactionKeyDown(event);" '.
      'onfocus="transCheckDate(this, true)" ' .
      'onblur="transCheckDate(this, true)" ' .
      'value="' . $row['date'] . '" ' .
    '/>' .
    '<br />'.
    '<label class="parsedDate"></label>'.
  '</td>' .
  '<td>' .
    '<input class="editTransactionDescr" type="text" ' .
      'onkeydown="editTransactionKeyDown(event);" '.
      'value="' . htmlspecialchars($row['description']) . '" />' .
  '</td>' .
  '<td>' .
    '<select class="editTransactionCategory">' .
      render_category_dropdown_contents($row['category']) .
    '</select>' .
  '</td>' .
  '<td>' .
    '<input class="amount" type="text" size="5" ' .
      'onkeydown="editTransactionKeyDown(event);" '.
      'value="' . $row['amount'] . '" />' .
  '</td>' .
  '<td>' . htmlspecialchars($row['currency_name']) . '</td>' .
  '<td>' .
    '<button class="btn-save" type="button" ' .
      'onclick="editTransactionSubmit(this)">' .
      'Save' .
    '</button> ' .
    '<button class="btn-cancel" type="button" '.
      'onclick="editTransactionCancel(this)">' .
      'Cancel' .
    '</button> ' .
    '<span class="editTransactionErr"></span>' .
  '</td>';

?>
