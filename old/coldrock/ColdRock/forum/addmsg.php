<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
?>
<html>
<head><title>Add a new topic</title></head>
<?
 include("../chenare/page_top.html");
?>
<body bgcolor="#000000" text="#CCCC99">
<b>
<form method="post" action="addmsg_act.php">
Message title:<input type="text" name="titlu" maxlength="200" size="50" lang="ro"><br><br>
Contents:<br>
<textarea cols="70" rows="10" wrap="soft" name="continut" lang="ro"></textarea><br><br>
<input type="submit" value="Send"></form>
</b>
</body>
</html>
