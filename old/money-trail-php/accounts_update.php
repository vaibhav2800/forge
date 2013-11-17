<?php
/**
 * POST parameters: id, name, currency.
 * Changes account name and currency.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$id = (int) POST_key_or_exit('id');
$name = POST_key_or_exit('name');
$currency = (int) POST_key_or_exit('currency');

$db = get_db();
$stmt =
  $db->prepare('UPDATE accounts SET name = :name, currency = :currency ' .
  'WHERE ID = :id;');
$stmt->bindValue(':id', $id, SQLITE3_INTEGER);
$stmt->bindValue(':name', $name, SQLITE3_TEXT);
$stmt->bindValue(':currency', $currency, SQLITE3_INTEGER);
$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());
exit_if($db->changes() === 0, 'not found');
?>
