<?php
/**
 * POST parameters: id, name.
 * Changes currency name.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$id = (int) POST_key_or_exit('id');
$name = POST_key_or_exit('name');

$db = get_db();
$stmt = $db->prepare('UPDATE currencies SET name = :name WHERE ID = :id;');
$stmt->bindValue(':id', $id, SQLITE3_INTEGER);
$stmt->bindValue(':name', $name, SQLITE3_TEXT);
$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());
exit_if($db->changes() === 0, 'not found');
?>
