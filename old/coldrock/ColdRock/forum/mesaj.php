<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("../chenare/page_top.html");
include("conectare.php");
$nr=$_GET['nr'];
$_SESSION['adresa']="mesaj.php?nr=".$nr;
if(mysql_num_rows(mysql_query("select * from mesaje where id_mesaj='".$nr."';"))!=1) {include("eroare.html");exit();}
$q="select id_topic from mesaje where id_mesaj='".$nr."';";
$rez=mysql_query($q);
$rez=mysql_fetch_array($rez);
$nrTopic=$rez['id_topic'];
$q="select titlu from topic where id_topic='".$nrTopic."';";
$rez=mysql_query($q);
$rez=mysql_fetch_array($rez);
$titluTopic=$rez['titlu'];
$q="select titlu from mesaje where id_mesaj='".$nr."';";
$rez=mysql_query($q);
$rez=mysql_fetch_array($rez);
$titluMesaj=$rez['titlu'];
?>

<body bgcolor="#000000" text="#CCCCCC">
<center>

<table border="0" cellspacing="10" cellpadding="0">

<tr><td></td>
<td><a href="forum.php"><b><font color="#00FFFF">Main</font></a> &rarr; <a href="topic.php?nr=<?=$nrTopic?>"><font color="#FFCCCC"><?=htmlentities($titluTopic)?></font></a> &rarr; <?=htmlentities($titluMesaj)?></b></td>
<td></td></tr>

<tr>
<td valign="top"><!--STANGA PAGINII-->
<?
 include("../chenare/stanga1.php");
?>
</td>

<td valign="top" align="center"><!-- CORPUL PAGINII -->
<table border="1" cellspacing="0" cellpadding="3">
<tr><td align="center" colspan="2" bgcolor="#CCCCCC"><strong><font color="#990099">Original message</font></strong></td></tr>
<tr><td align="center">Author</td><td width="500" align="center">Contents</td></tr>
<?
$q="select * from mesaje where id_mesaj='".$nr."';";
$rez=mysql_query($q);
$a=mysql_fetch_array($rez);
$n1="select nume from useri where id_user='".$a['id_user']."';";
$nrez=mysql_fetch_array(mysql_query($n1));
$data=strtotime($a['data']);
$data1=date("d M Y",$data);
$data2=date("H:i:s",$data);
?>

<tr>
<td nowrap align="center"><a href="membri.php?id=<?=$a['id_user']?>"><p><font color=#FFCCFF>

<?
print htmlentities($nrez['nume'])."</font></p>";
include("../chenare/poza.php");
print "</a>";
print "<br><font color=#00CC99>$data1<br>$data2</font></td><td>".nl2br(htmlentities($a['continut']))."</td>";
print "</tr>";
?>
<tr><td align="center" colspan="2" bgcolor="#cccccc"><strong><font color=red>Message replies</font></strong></td></tr>
<?
$q="SELECT reply.id_reply, reply.id_user, reply.continut, reply.data, useri.nume ".
	"FROM	reply, useri ".
	"WHERE	reply.id_user = useri.id_user AND reply.id_mesaj = '".$nr."' ".
	"ORDER BY reply.data;";
$rez=mysql_query($q);
while($a=mysql_fetch_array($rez)){
	$data=strtotime($a['data']);
	$data1=date("d M Y",$data);
	$data2=date("H:i:s",$data);
?>
	<tr>
	<td align="center">
	<a href="membri.php?id=<?=$a['id_user']?>"><p><font color=#FFCCFF>

<?
	print nl2br(htmlentities($a['nume']))."</font></p>";
	include("../chenare/poza.php");
	print "</a><br><font color=#00CC99>$data1<br>$data2</font></td><td>".nl2br(htmlentities($a['continut']))."</td>";
	print "</tr>";
}	//de la while
$_SESSION['id_mesaj']=$nr;
?>
</table>

<br />
<a href="addreply.php"><font color="#00FF00" size="3"><b>Add a reply</b></font></a>

</td><!-- Se termina corpul paginii-->

<td valign="top" align="center"><!--PARTEA DIN DREAPTA -->
<?
include("../chenare/dreapta1.php");
?>
<br><br>
<a href="addreply.php"><font color="#F9F1E7" size="3" face="Courier New, Courier, mono"><b>Add a reply</b></font></a>
</td><!--SE TERMINA PARTEA DIN DREAPTA-->
</table>
</center>

</font>
</body>
