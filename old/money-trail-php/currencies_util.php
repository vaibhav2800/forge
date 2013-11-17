<?php

require_once './db.php';

/**
 * Returns a full HTML table row '<tr>..</tr>'.
 * @see render_currency_row_contents() for the required parameter.
 */
function render_currency_row($row) {
  return
    '<tr id="currency_' . $row['ID'] . '">' .
      render_currency_row_contents($row) .
    '</tr>';
}


/*
 * Returns the contents of an HTML table row (i.e. without '<tr>' and '</tr>').
 * Needs a DB row with 'ID' and 'name'.
 */
function render_currency_row_contents($row) {
  return
    '<td>' . htmlspecialchars($row['name']) . '</td>' .
    '<td>' .
      '<button type="button" onclick="editCurrencyForm(this)">edit</button> ' .
      '<button type="button" onclick="deleteCurrency(this)">delete</button> ' .
      '<span></span>' .
    '</td>';
}


/*
 * Returns a full HTML <select>..</select>.
 * @see render_currency_dropdown_contents() for the parameter.
 */
function render_currency_dropdown($account_id = -1) {
  return
    '<select>' . render_currency_dropdown_contents($account_id) . '</select>';
}


/*
 * Returns the options of a HTML 'select' (i.e. without <select> and </select>)
 * with the currency of the specified account-preselected (if 'account_id' is
 * invalid, it's ignored).
 */
function render_currency_dropdown_contents($account_id = -1) {
  $db = get_db();

  $stmt = $db->prepare('SELECT currency FROM accounts WHERE ID = :id;');
  $stmt->bindValue(':id', $account_id, SQLITE3_INTEGER);
  $results = $stmt->execute();

  $selected_id = -1;
  if ($row = $results->fetchArray()) {
    $selected_id = (int) $row['currency'];
  }

  $stmt->close();

  $results = $db->query('SELECT ID, name FROM currencies ORDER BY name ASC;');

  $str = '';
  while ($row = $results->fetchArray()) {
    $str .= '<option value="' . $row['ID'] . '"';
    if ($row['ID'] == $selected_id)
      $str .= ' selected="selected"';
    $str .= '>';
    $str .= htmlspecialchars($row['name']);
    $str .= '</option>';
  }

  return $str;
}

?>
