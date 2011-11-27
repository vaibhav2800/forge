<?php
$v1 = array_key_exists('v1', $_GET) ? $_GET['v1'] : 'undefined';
$v2 = array_key_exists('v2', $_GET) ? $_GET['v2'] : 'undefined';
if (!in_array($v2, array('1', '2', '3')))
    $v2 = '2';
?>

<td><?php echo $v1;?></td>
<td><?php
if ($v2 == '1')
    echo 'One';
else if ($v2 == '2')
    echo 'Two';
else
    echo 'Three';
?></td>
<td><button type="button" onclick="editRow(this)">edit</button></td>
