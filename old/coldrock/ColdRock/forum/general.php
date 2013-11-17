<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("../chenare/page_top.html");
?>
<body>
<center>

<table border="0" cellspacing="10" cellpadding="0" align="center">
<tr><td></td>
<td><font color="#cccccc"><b>Main</b></font></td>
<td></td></tr>

<tr>
<td valign="top" align="left">
<?
 include("../chenare/stanga1.php");
?>
</td>

<td valign="top" align="center"><!-- CORPUL PAGINII -->

<table border="1" cellspacing="0" cellpadding="3">
<tr><td colspan="4" align="center" bgcolor="#CCCCCC"><font color=blue><strong>Topics in the forum:</strong></font></td></tr>
<tr><td width="100px" align="center">user</td><td width="200px" align="center">title</td><td width="300px" align="center">description</td><td width="100px" align="center">Last post</td></tr>
<?
include("conectare.php");
$q="SELECT topic.id_topic, topic.id_user, topic.titlu, topic.data, ".
	"topic.lastpost,topic.descriere, useri.nume ".
	"FROM	topic, useri ".
	"WHERE	topic.id_user = useri.id_user ".
	"ORDER BY topic.data;";
$rez=mysql_query($q);
while($a=mysql_fetch_array($rez)){
	$link="<a href=\"topic.php?nr=".$a['id_topic']."\">";

	print "<tr>";
	print "<td align=\"center\">";
	print "<a href=\"membri.php?id=".$a[id_user]."\"><p><font color=#FFCCFF>";
	print htmlentities($a['nume'])."</font></p>";
	include("../chenare/poza.php");
	print "</a>";
	$data=strtotime($a['data']);
	$data1=date("d M Y",$data);
	$data2=date("H:i:s",$data);
	print "<font color=#00CC99><br>$data1<br>$data2</font>";
	print "</td>";

	print "<td align=\"center\">".$link.htmlentities($a['titlu'])."</a></td>";
	print "<td align=\"center\">".htmlentities($a['descriere'])."</td>";

	$data = strtotime($a['lastpost']);
	$data1 = date("d M Y", $data);
	$data2 = date("H:i:s", $data);
	print "<td align=\"center\">$data1<br />$data2</td>";
	print "</tr>";
}
?>

</table>

<br /> <br />
<a href="addtopic.php"><font color="#00FF00" size=3><b>Add a new topic</b></font></a>


</td><!-- Se termina corpul paginii-->

<td valign="top" align="center"><!--PARTEA DIN DREAPTA-->
<?
 include("../chenare/dreapta1.php");
?>
<br><br>
<center>
<a href="addtopic.php"><font color="#F9F1E7" size="3" face="Courier New, Courier, mono"><b>Add a new topic</b></font></a>
</center>
</td><!--SE TERMINA PARTEA DIN DREAPTA -->
</center>

</tr></table>
</body>
</html>
