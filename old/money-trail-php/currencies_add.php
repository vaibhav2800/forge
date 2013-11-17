<?php
/**
 * POST parameter: name.
 * Inserts a new currency with this name.
 * HTML response code represents success.
 * For errors, the page text tries to explain.
 */
require_once './db.php';
require_once './util.php';

$name = POST_key_or_exit('name');

$db = get_db();
$stmt = $db->prepare('INSERT INTO currencies(\'name\') VALUES(:name);');
$stmt->bindValue(':name', $name, SQLITE3_TEXT);
$results = exec_without_warnings($stmt);

exit_if($results === false, $db->lastErrorMsg());
?>
