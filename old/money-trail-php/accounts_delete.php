<?php
/**
 * POST parameter: id.
 * Deletes account with given ID.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$id = (int) POST_key_or_exit('id');

$db = get_db();
$stmt = $db->prepare('DELETE FROM accounts WHERE ID = :id;');
$stmt->bindValue(':id', $id, SQLITE3_INTEGER);
$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());
exit_if($db->changes() === 0, 'not found');
?>
