<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("../chenare/page_top.html");
include("conectare.php");
$nr=$_GET['nr'];
$_SESSION['adresa']="topic.php?nr=".$nr;
$q="select * from topic where id_topic='".$nr."';";
$rez=mysql_query($q);
if(mysql_num_rows($rez)!=1) {include("eroare.html");exit();}
$rez=mysql_fetch_array($rez);
$topic=$rez['titlu'];
?>
<body>
<center>

<table border="0" cellspacing="10" cellpadding="0" align="center">
<tr><td></td>
<td><a href="forum.php"><font color="#00FFFF"><b>Main</b></font></a> &rarr; <?=htmlentities($topic)?></td>
<td></td></tr>

<tr>
<td valign="top" align="center" width="120">
<?
 include("../chenare/stanga1.php");
?>
</td>

<td valign="top"><!-- CORPUL PAGINII -->


<center>
<table align="center" border="1" cellspacing="0" cellpadding="3">
<tr><td colspan="3" align="center" bgcolor="#CCCCCC"><font color=blue><strong>Messages</strong></font></td></tr>
<tr><td width="100" align="center">user</td><td width="300" align="center">Titlu</td><td width="100" align="center">Last post</td></tr>
<?
$q="SELECT	mesaje.id_mesaj, mesaje.id_user, mesaje.continut, mesaje.data, mesaje.lastpost, ".
		"mesaje.titlu, useri.nume ".
		"FROM	mesaje, useri ".
		"WHERE	mesaje.id_user = useri.id_user AND mesaje.id_topic = '".$nr."' ".
		"ORDER BY mesaje.data;";
$rez=mysql_query($q);
while($a=mysql_fetch_array($rez)){
	$link="<a href=\"mesaj.php?nr=".$a['id_mesaj']."\">";

	print "<tr>";
	print "<td align=\"center\" width=\"100\">";
	print "<a href=\"membri.php?id=".$a[id_user]."\"><p><font color=#FFCCFF>";
	print htmlentities($a['nume'])."</font></p>";
	include("../chenare/poza.php");
	print "</a>";
	$data=strtotime($a['data']);
	$data1=date("d M Y",$data);
	$data2=date("H:i:s",$data);
	print "<font color=#00CC99><br>$data1<br>$data2</font>";
	print "</td>";

	print "<td align=\"center\">".$link.htmlentities($a['titlu'])."</font></a></td>";
	print "<td align=\"center\">".$a['lastpost']."</td>";
	print "</tr>";
}
$_SESSION['id_topic']=$nr;
?>
</table>

<br />
<a href="addmsg.php"><font color="#00FF00" size="3"><b>Add a new message</b></font></a>

</td><!-- Se termina corpul paginii-->

<td valign="top" align="center" width="125"><!--PARTEA DIN DREAPTA-->
<?
 include("../chenare/dreapta1.php");
?>
<br /><br />
<center>
<a href="addmsg.php"><font color="#F9F1E7" size="3" face="Courier New, Courier, mono"><b>Add a new message</b></font></a>
</center>
</td><!--SE TERMINA PARTEA DIN DREAPTA -->
</table>
</center>

</body>
</html>
