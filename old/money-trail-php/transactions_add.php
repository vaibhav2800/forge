<?php
/**
 * POST parameters: from_acc, to_acc, date, descr, categ, amount.
 * If an account is NULL (i.e. payment or income) the parameter's value must be
 * the string NULL.
 * Adds a new transaction.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$from_acc = POST_key_or_exit('from_acc');
$to_acc = POST_key_or_exit('to_acc');

$date = get_date_or_exit(POST_key_or_exit('date'));
$descr = POST_key_or_exit('descr');
$categ = (int) POST_key_or_exit('categ');
$amount = (int) POST_key_or_exit('amount');

$db = get_db();
$stmt = $db->prepare(
  'INSERT INTO transactions (\'from_account\', \'to_account\', \'date\', ' .
  '\'description\', \'category\', \'amount\') ' .
  'VALUES(:from_acc, :to_acc, :date, :descr, :categ, :amount);');

if ($from_acc === 'NULL')
  $stmt->bindValue(':from_acc', null, SQLITE3_NULL);
else
  $stmt->bindValue(':from_acc', (int)$from_acc, SQLITE3_INTEGER);

if ($to_acc === 'NULL')
  $stmt->bindValue(':to_acc', null, SQLITE3_NULL);
else
  $stmt->bindValue(':to_acc', (int)$to_acc, SQLITE3_INTEGER);

$stmt->bindValue(':date', $date, SQLITE3_TEXT);
$stmt->bindValue(':descr', $descr, SQLITE3_TEXT);
$stmt->bindValue(':categ', $categ, SQLITE3_INTEGER);
$stmt->bindValue(':amount', $amount, SQLITE3_INTEGER);

$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());

?>
