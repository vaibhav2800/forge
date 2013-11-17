<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("../chenare/page_top.html");
include("conectare.php");
?>

<body>
<center>
<table border="0" cellspacing="10" cellpadding="0" align="center">
<tr><td></td>
<td><a href="forum.php"><font color="#00FFFF"><b>Main</b></font></a> -> Private messaging user activity report</td>
<td></td></tr>

<tr>
<td valign="top" align="center" width="120">
<?
 include("../chenare/stanga1.php");
?>
</td>

<td valign="top"><!-- CORPUL PAGINII -->
<center>

<!-- this table has 1 row and 3 columns - for the 3 message report tables -->
<table valign="top" cellspacing="10">
<tr>
<td valign="top">

<table align="center" border="1" cellspacing="0" cellpadding="3">
<tr><td colspan="2" align="center" bgcolor="#CCCCCC"><font color=blue><strong>Top private messagers</strong></font></td></tr>
<tr><td width="100" align="center">User</td><td width="100" align="center">Total msg count</td></tr>

<?
$q_total = "SELECT useri.id_user, COUNT(priv_mesg.id_msg) msgcount, useri.nume ".
	"FROM priv_mesg, useri ".
	"WHERE useri.id_user = priv_mesg.id_sender OR useri.id_user = priv_mesg.id_receiver ".
	"GROUP BY useri.id_user ".
	"ORDER BY msgcount desc ".
	"LIMIT 0, 10;";

$rez = mysql_query($q_total);

while($a=mysql_fetch_array($rez)){
	print "<tr>";
	print "<td align=\"center\" width=\"100\">";
	print "<a href=\"membri.php?id=".$a[id_user]."\"><p><font color=#FFCCFF>";
	print htmlentities($a['nume'])."</font></p>";
	include("../chenare/poza.php");
	print "</a>";
	print "</td>";
	print "<td align=\"center\"><font size=\"5\">".$a['msgcount']."</font></td>";
	print "</tr>";
}
?>

</table>
</td>

<td valign="top">
<table align="center" border="1" cellspacing="0" cellpadding="3">
<tr><td colspan="2" align="center" bgcolor="#CCCCCC"><font color=blue><strong>Top senders</strong></font></td></tr>
<tr><td width="100" align="center">User</td><td width="100" align="center">Messages sent</td></tr>

<?
$q_sent = "SELECT useri.id_user, COUNT(id_msg) msgcount, useri.nume ".
	"FROM priv_mesg, useri ".
	"WHERE useri.id_user = priv_mesg.id_sender ".
	"GROUP BY id_sender ".
	"ORDER BY msgcount desc;";

$rez = mysql_query($q_sent);

while($a=mysql_fetch_array($rez)){
	print "<tr>";
	print "<td align=\"center\" width=\"100\">";
	print "<a href=\"membri.php?id=".$a[id_user]."\"><p><font color=#FFCCFF>";
	print htmlentities($a['nume'])."</font></p>";
	include("../chenare/poza.php");
	print "</a>";
	print "</td>";
	print "<td align=\"center\"><font size=\"5\">".$a['msgcount']."</font></td>";
	print "</tr>";
}
?>

</table>
</td>

<td valign="top">
<table align="center" border="1" cellspacing="0" cellpadding="3">
<tr><td colspan="2" align="center" bgcolor="#CCCCCC"><font color=blue><strong>Top receivers</strong></font></td></tr>
<tr><td width="100" align="center">User</td><td width="100" align="center">Messages Received</td></tr>

<?
$q_recv = "SELECT useri.id_user, COUNT(id_msg) msgcount, useri.nume ".
	"FROM priv_mesg, useri ".
	"WHERE useri.id_user = priv_mesg.id_receiver ".
	"GROUP BY id_receiver ".
	"ORDER BY msgcount desc;";

$rez = mysql_query($q_recv);

while($a=mysql_fetch_array($rez)){
	print "<tr>";
	print "<td align=\"center\" width=\"100\">";
	print "<a href=\"membri.php?id=".$a[id_user]."\"><p><font color=#FFCCFF>";
	print htmlentities($a['nume'])."</font></p>";
	include("../chenare/poza.php");
	print "</a>";
	print "</td>";
	print "<td align=\"center\"><font size=\"5\">".$a['msgcount']."</font></td>";
	print "</tr>";
}
?>

</table>
</td>

</tr>
</table> <!-- the table containing 1 row and 3 columns for the 3 reports -->

</td><!-- Se termina corpul paginii-->

<td valign="top" align="center" width="125"><!--PARTEA DIN DREAPTA-->
<?
 include("../chenare/dreapta1.php");
?>
</td><!--SE TERMINA PARTEA DIN DREAPTA -->

</table>
</center>
</body>
</html>
