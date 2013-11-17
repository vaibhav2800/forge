<?
include("e_logat.php");
include("conectare.php");
?>
<html>
<head>
<title>Private messages</title>
<link rel="stylesheet" type="text/css"
href="../chenare/standard.css" />
</head>

<body>
<center>
  <img src="../imagini/logo.jpg" width="909" height="129" border="0" usemap="#MapLogo"> 
  <map name="MapLogo">
  <area shape="circle" coords="450,66,82" href="../forum/forum.php">
</map>
</center>

<table border="0" cellspacing="10" cellpadding="0" align="center">

<tr><td></td>
<td><a href="forum.php"><font color="#00FFFF"><b>Main</b></font></a> -> View private messages</td>
<td></td>
<td></td></tr>

<tr>
<td valign="top" align="left">
<?
 include("../chenare/stanga1.php");
?>
</td>

<td valign="top">

<?
$q="SELECT priv_mesg.id_msg, priv_mesg.id_sender, useri.nume, priv_mesg.senddate, priv_mesg.contents ".
	"FROM	priv_mesg, useri ".
	"WHERE	priv_mesg.id_receiver = '".$_SESSION['id_user']."' AND priv_mesg.id_sender = useri.id_user;";
$rez=mysql_query($q);
if (mysql_num_rows($rez) == 0) {
	?>
	<table valign="top" width="500">
		<tr><td align="center"><font size="5">You have no private messages.</font></td></tr>
	</table>
	<?
}
else {
	?>
	<table border="1" cellspacing="0" cellpadding="3" align="center">
	<tr><td align="center" colspan="3" bgcolor="#CCCCCC"><strong><font color="#990099">Private messages</font></strong></td></tr>
	<tr><td align="center" width="100px">Sender</td><td width="500px" align="center">Contents</td><td>Delete</td></tr>
	<?
	while($a=mysql_fetch_array($rez)){
		$data=strtotime($a['senddate']);
		$data1=date("d M Y",$data);
		$data2=date("H:i:s",$data);
	?>
		<tr>
		<td align="center">
		<a href="membri.php?id=<?=$a['id_sender']?>"><p><font color=#FFCCFF>

	<?
		print nl2br(htmlentities($a['nume']))."</font></p>";
		$a['id_user'] = $a['id_sender'];	//for "poza.php"
		include("../chenare/poza.php");
		print "</a><br><font color=#00CC99>$data1<br>$data2</font></td><td>".nl2br(htmlentities($a['contents']))."</td>\n";
		print "<td><a href=\"del_privmsg.php?id=".$a['id_msg']."\"><font color=\"red\">delete</font></a></td>\n";
		print "</tr>\n";
	}
	print "</table>";
}
?>

</td>

<td valign="top" align="center"><!--PARTEA DIN DREAPTA-->
<?
 include("../chenare/dreapta1.php");
?>
</td>

</table>

</body>
</html>
