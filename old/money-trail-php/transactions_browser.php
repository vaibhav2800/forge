<?php
/**
 * GET parameters: for_account (optional), offset (optional).
 * Returns HTML code for the transactions browser.
 * If 'for_account' given, only its transactions are shown.
 * To show all accounts omit 'for_account' or pass -1.
 * $offset is 0-based.
 */
require_once './util.php';
require_once './transactions_util.php';

$for_account = (int) array_key_or_default('for_account', $_GET, -1);
$offset = (int) array_key_or_default('offset', $_GET, 1);
echo render_transactions_browser($for_account, $offset);
?>
