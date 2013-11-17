<?php
/**
 * GET parameter: date.
 * Parses date and outputs YYYY-MM-DD if successful.
 * HTML response code represents success.
 * For errors, the page text contains an error.
 */

require_once './util.php';

$date = GET_key_or_exit('date');
echo get_date_or_exit($date);
?>
