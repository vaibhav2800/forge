<?php
/**
 * POST parameters: name, currency.
 * Inserts a new account with this name and this currency id.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$name = POST_key_or_exit('name');
$currency = (int) POST_key_or_exit('currency');

$db = get_db();
$stmt = $db->prepare('INSERT INTO accounts(\'name\', \'currency\') ' .
  'VALUES(:name, :currency);');
$stmt->bindValue(':name', $name, SQLITE3_TEXT);
$stmt->bindValue(':currency', $currency, SQLITE3_INTEGER);
$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());
?>
