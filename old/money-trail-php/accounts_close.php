<?php
/**
 * POST parameters: id, close.
 * Closes (if close="true", else opens) account with given ID.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$id = (int) POST_key_or_exit('id');
$close_key = POST_key_or_exit('close');
if ($close_key === 'true') {
  $close = true;
} elseif ($close_key === 'false') {
  $close = false;
} else {
  exit_if(true, 'Invalid \'close\' parameter: ' . $close_key);
}

$db = get_db();
$stmt = $db->prepare('UPDATE accounts SET closed = :close WHERE ID = :id;');
$stmt->bindValue(':id', $id, SQLITE3_INTEGER);
$stmt->bindValue(':close', $close ? 1 : 0, SQLITE3_INTEGER);
$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());
exit_if($db->changes() === 0, 'not found');
?>
