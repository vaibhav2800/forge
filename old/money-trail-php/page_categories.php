<?php
require_once './db.php';
require_once './categories_util.php';

$db = get_db();
$results = $db->query('SELECT ID, name FROM categories ORDER BY name ASC;');
?>

<div class="newItemArea newCategoryArea">
  <p id="newCategoryPreForm">
    <button type="button" onclick="newCategoryForm()">Add New Category</button>
  </p>

  <p id="newCategoryForm" hidden="hidden">
    <label for="newCategoryName">New Category:</label>
    <input type="text" id="newCategoryName"
      onkeydown="newCategoryKeyDown(event)" />
    <button type="button" onclick="newCategorySubmit()">Add</button>
    <button type="button" onclick="newCategoryCancel()">Cancel</button>
    <span id="newCategoryError"></span>
  </p>
</div>

<!-- This outer, unstyled div takes up the whole page width preventing
newItemArea and existingItemsArea (which have display: inline-block;) from
getting put side by side. -->
<div>
  <div class="existingItemsArea">
    <table id="categoryTable">
      <?php
      while ($row = $results->fetchArray()) {
        echo render_category_row($row);
      }
      ?>
    </table>
  </div>
</div>
