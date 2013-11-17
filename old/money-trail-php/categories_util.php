<?php

require_once './db.php';

/**
 * Returns a full HTML table row '<tr>..</tr>'.
 * @see render_category_row_contents() for the required parameter.
 */
function render_category_row($row) {
  return
    '<tr id="category_' . $row['ID'] . '">' .
      render_category_row_contents($row) .
    '</tr>';
}


/*
 * Returns the contents of an HTML table row (i.e. without '<tr>' and '</tr>').
 * Needs a DB row with 'ID' and 'name'.
 */
function render_category_row_contents($row) {
  return
    '<td>' . htmlspecialchars($row['name']) . '</td>' .
    '<td>' .
      '<button type="button" onclick="editCategoryForm(this)">edit</button> ' .
      '<button type="button" onclick="deleteCategory(this)">delete</button> ' .
      '<span></span>' .
    '</td>';
}


/*
 * Returns a full HTML <select>..</select>.
 * @see render_category_dropdown_contents() for the parameter.
 */
function render_category_dropdown($category_id = -1) {
  return
    '<select>' . render_category_dropdown_contents($category_id) . '</select>';
}


/*
 * Returns the options of a HTML 'select' (i.e. without <select> and </select>)
 * with the specified category preselected (if 'category_id' is invalid,
 * it's ignored).
 */
function render_category_dropdown_contents($category_id = -1) {
  $db = get_db();

  $results = $db->query('SELECT ID, name FROM categories ORDER BY name ASC;');

  $str = '';
  while ($row = $results->fetchArray()) {
    $str .= '<option value="' . $row['ID'] . '"';
    if ($row['ID'] == $category_id)
      $str .= ' selected="selected"';
    $str .= '>';
    $str .= htmlspecialchars($row['name']);
    $str .= '</option>';
  }

  return $str;
}

?>
