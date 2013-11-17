<?php

/**
 * Returns $_POST[$key] or sets HTTP status 400, echoes a message and exit()s.
 */
function POST_key_or_exit($key) {
  return array_key_or_exit($key, $_POST, 'missing POST parameter "'.$key.'"');
}


/**
 * Returns $_GET[$key] or sets HTTP status 400, echoes a message and exit()s.
 */
function GET_key_or_exit($key) {
  return array_key_or_exit($key, $_GET, 'missing GET parameter "'.$key.'"');
}


/**
 * Returns $arr[$key] or sets HTTP status 400, echoes $msg and exit()s.
 */
function array_key_or_exit($key, $arr, $msg) {
  exit_if(!array_key_exists($key, $arr), $msg);
  return $arr[$key];
}


/**
 * Returns $arr[$key] or $default.
 */
function array_key_or_default($key, $arr, $default) {
  if(array_key_exists($key, $arr))
    return $arr[$key];
  return $default;
}


/**
 * If $condition sets HTTP status 400, echoes $msg and exit()s.
 */
function exit_if($condition, $msg) {
  if ($condition) {
    header('-', true, 400);
    echo $msg;
    exit();
  }
}


/**
 * Set error_reporting(E_ERROR) before $stmt->execute() then set it back to its
 * previous value.
 * This disables warnings in page output (such as 'constraint failed')
 * if the caller wants to show a different message.
 *
 * Returns $stmt->execute();
 */
function exec_without_warnings(SQLite3Stmt $stmt) {
  $err_lvl = error_reporting(E_ERROR);
  $results = $stmt->execute();
  error_reporting($err_lvl);

  return $results;
}


/**
 * Returns a string in 'YYYY-MM-DD' format or sets HTTP status 400, echoes
 * an error message and exit()s.
 */
function get_date_or_exit($str) {
  try {
    $dt = new DateTime($str, new DateTimeZone('UTC'));
    return $dt->format('Y-m-d');
  } catch (Exception $e) {
    exit_if(true, 'invalid date');
  }
}

?>
