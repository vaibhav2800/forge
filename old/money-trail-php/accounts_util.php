<?php

require_once './db.php';


/**
 * Returns the query string for selecting accounts.
 * If $open_accounts is true, selects open accounts, else selects closed ones.
 */
function get_account_data_query_string($open_accounts) {
  return
    'SELECT accounts.ID, accounts.name AS account_name, accounts.closed, ' .
    'currencies.name AS currency_name, ' .
    '(' .
    'SELECT IFNULL(' .
      'SUM(CASE accounts.ID WHEN from_account THEN -amount ELSE amount END), '.
      '0) ' .
    'FROM transactions '.
    'WHERE from_account = accounts.ID OR to_account = accounts.ID' .
    ') '.
    'AS balance ' .
    'FROM accounts, currencies ' .
    'WHERE accounts.currency = currencies.ID ' .
    'AND closed ' . ($open_accounts === true ? '= 0 ' : '!= 0 ') .
    'ORDER BY accounts.name ASC;';
}


/**
 * Returns the number of accounts.
 * If $open_accounts is true, counts open accounts, else counts closed ones.
 */
function get_account_count($open_accounts) {
  $db = get_db();
  $result = $db->query(
    'SELECT COUNT(*) AS count FROM accounts ' .
    'WHERE closed ' . ($open_accounts === true ? '= 0 ' : '!= 0 ')
  );
  $row = $result->fetchArray();
  return $row['count'];
}


/**
 * Returns a full HTML table row '<tr>..</tr>'.
 * @see render_account_row_contents() for the required parameter.
 */
function render_account_row($row) {
  return
    '<tr id="account_' . $row['ID'] . '">' .
      render_account_row_contents($row) .
    '</tr>';
}


/*
 * Returns the contents of an HTML table row (i.e. without '<tr>' and '</tr>').
 * Needs a DB row with 'ID', 'account_name', 'currency_name' and 'balance'.
 */
function render_account_row_contents($row) {
  $is_closed = $row['closed'] === 1;
  return
    '<td>' . htmlspecialchars($row['account_name']) . '</td>' .
    '<td class="amount">' . number_format($row['balance']) . '</td>' .
    '<td>' . htmlspecialchars($row['currency_name']) . '</td>' .
    '<td>' .
      '<button type="button" onclick="editAccountForm(this)">edit</button> ' .
      '<button type="button" onclick="deleteAccount(this)">delete</button> ' .
      '<button type="button" onclick="closeOrOpenAccount(this, ' .
        ($is_closed ? 'false' : 'true') . ')">' .
        ($is_closed ? 'open' : 'close') . '</button> ' .
      '<span></span>' .
    '</td>';
}


/*
 * Returns a full HTML <select>..</select>.
 * @see render_accounts_dropdown_contents() for the parameters.
 */
function render_accounts_dropdown($selected_id = -1, $transfer_from = -1) {
  return
    '<select>' .
      render_accounts_dropdown_contents($selected_id, $transfer_from) .
    '</select>';
}


/*
 * Returns the options of an HTML select (ie. without <select> and </select>).
 * Does not include closed accounts.
 * The option with $selected_id is preselected; if $selected_id is invalid it's
 * ignored.
 * If $transfer_from is -1, all accounts are shown in the dropdown.
 * Otherwise $transfer_from is an account ID, and the dropdown only contains
 * accounts with the same currency (excluding $transfer_from itself).
 */
function render_accounts_dropdown_contents($selected_id = -1,
                                           $transfer_from = -1) {
  $db = get_db();

  $sql_start =
    'SELECT accounts.ID, accounts.name, currencies.name AS currency_name ' .
    'FROM accounts, currencies WHERE accounts.currency = currencies.ID ' .
    'AND accounts.closed = 0 ';
  $sql_end = ' ORDER BY accounts.name ASC;';

  if ($transfer_from == -1) {
    $sql = $sql_start . $sql_end;
    $results = $db->query($sql);
  } else {
    $sql =
      $sql_start .
      ' AND ' .
      'accounts.currency = (SELECT currency FROM accounts WHERE ID = :id) ' .
      'AND accounts.ID != :id ' .
      $sql_end;
    $stmt = $db->prepare($sql);
    $stmt->bindValue(':id', $transfer_from, SQLITE3_INTEGER);
    $results = $stmt->execute();
  }

  $str = '';
  while ($row = $results->fetchArray()) {
    $str .= '<option value="' . $row['ID'] . '"';
    if ($row['ID'] == $selected_id)
      $str .= ' selected="selected"';
    $str .= '>';
    $str .= htmlspecialchars($row['name']);
    $str .= ' (' . htmlspecialchars($row['currency_name']) . ')';
    $str .= '</option>';
  }

  return $str;
}

?>
