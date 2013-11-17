<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
?>
<html>
<head><title>Add a reply</title></head>
<?
include("../chenare/page_top.html");
?>

<body bgcolor="#000000" text="#CCCC99">
<b>

<form method="post" action="addreply_act.php">
Reply message:<br>
<textarea cols="70" rows="10" wrap="soft" name="continut" lang="ro"></textarea><br><br>
<input type="submit" value="Send"></form>
</b>
</body>
</html>
