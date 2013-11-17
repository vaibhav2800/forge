<?php
/**
 * GET parameter: id.
 * Returns the currency of the specified account as plain text.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$id = (int) GET_key_or_exit('id');

$db = get_db();
$stmt = $db->prepare('SELECT currencies.name FROM currencies, accounts ' .
  'WHERE accounts.currency = currencies.ID AND accounts.ID = :id;');
$stmt->bindValue(':id', $id, SQLITE3_INTEGER);
$results = $stmt->execute();

$row = $results->fetchArray();
exit_if(!$row, 'no account with ID ' . $id . ' found');

echo $row['name'];
?>
