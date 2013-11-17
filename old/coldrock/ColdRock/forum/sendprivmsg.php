<?
include("e_logat.php");
include("conectare.php");
$id = $_GET['id'];
if(mysql_num_rows(mysql_query("select id_user from useri where id_user='".$id."';"))!=1) {include("eroare.html");exit();}
$_SESSION['id_receiver'] = $id;
?>
<html>
<head>
<title>ColdRock</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<style type="text/css">
<!--
@import url("../chenare/standard.css");
-->
	</style>
	</head>

<body bgcolor="#000000" text="#CCCC99">
	<center>
	  <img src="../imagini/logo.jpg" width="909" height="129" border="0" usemap="#MapLogo"> 
	    <map name="MapLogo">
	      <area shape="circle" coords="450,66,82" href="../forum/forum.php">
	      </map>
	      </center>
<br /><br />
<b>

<form method="post" action="sendprivmsg_act.php">
Message:<br>
<textarea cols="70" rows="10" wrap="soft" name="continut" lang="ro"></textarea>
<br /><br />
<input type="submit" value="Send">
</form>
</body>
</html>
