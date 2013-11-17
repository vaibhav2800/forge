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
<form method="post" action="addtopic_act.php">
Topic title:<input type="text" name="titlu" maxlength="50" size="50" lang="ro"><br><br>
Description:<input type="text" name="descriere" maxlength="200" size="100" lang="ro"><br><br>
<input type="submit" value="Send"></form>
</b>
</body>
</html>
