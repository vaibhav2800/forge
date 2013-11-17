<?php
/**
 * GET parameters: id (optional), transfer_from (optional).
 * Returns HTML code for the <option>s of a <select> element
 * (i.e. without the <select> and </select> tags).
 * If 'id' given, it's preselected. If invalid, it's ignored.
 * If 'transfer_from' given, only accounts with the same currency as it are
 * returned.
 */
require_once './util.php';
require_once './accounts_util.php';

$id = (int) array_key_or_default('id', $_GET, -1);
$transfer_from = (int) array_key_or_default('transfer_from', $_GET, -1);
echo render_accounts_dropdown_contents($id, $transfer_from);
?>
