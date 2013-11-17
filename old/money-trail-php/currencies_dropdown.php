<?php
/**
 * GET parameter: for_account (optional).
 * Returns HTML code for <select>..</select>. If 'for_account' given, its
 * currency is preselected.
 */
require_once './util.php';
require_once './currencies_util.php';

$for_account = (int) array_key_or_default('for_account', $_GET, -1);
echo render_currency_dropdown($for_account);
?>
