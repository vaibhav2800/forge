<?php
$v1 = array_key_exists('v1', $_GET) ? $_GET['v1'] : 'undefined';
$v2 = array_key_exists('v2', $_GET) ? $_GET['v2'] : 'undefined';
if (!in_array($v2, array('One', 'Two', 'Three')))
    $v2 = 'Two';

function echo_if_selected($val) {
    global $v2;
    if ($v2 == $val)
        echo 'selected="selected"';
}
?>

<td><input type="text" value="<?php echo $v1?>"/></td>
<td>
    <select>
        <option value="1" <?php echo_if_selected('One');?> >
            One
        </option>
        <option value="2" <?php echo_if_selected('Two');?> >
            Two
        </option>
        <option value="3" <?php echo_if_selected('Three');?> >
            Three
        </option>
    </select>
</td>
<td><button type="button" onclick="saveRow(this)">save</button></td>
