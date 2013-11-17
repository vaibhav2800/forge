<?php
/**
 * POST parameters: id, date, description, category, amount.
 * Update transaction.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$id = (int) POST_key_or_exit('id');
$date = get_date_or_exit(POST_key_or_exit('date'));
$description = POST_key_or_exit('description');
$category = (int) POST_key_or_exit('category');
$amount = (int) POST_key_or_exit('amount');

$db = get_db();
$stmt = $db->prepare('UPDATE transactions ' .
  'SET date = :date, description = :description, category = :category, ' .
  'amount = :amount WHERE ID = :id;');
$stmt->bindValue(':id', $id, SQLITE3_INTEGER);
$stmt->bindValue(':date', $date, SQLITE3_TEXT);
$stmt->bindValue(':description', $description, SQLITE3_TEXT);
$stmt->bindValue(':category', $category, SQLITE3_INTEGER);
$stmt->bindValue(':amount', $amount, SQLITE3_INTEGER);
$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());
exit_if($db->changes() === 0, 'not found');
?>
