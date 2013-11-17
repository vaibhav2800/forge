<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("conectare.php");
include("../chenare/page_top.html");
?>
<center>
<br><br><p>
<body bgcolor="#000000" text="#CCCCCC">
<font color="#FF9900" size="3" face="Courier New, Courier, mono"><b>Lista membrilor</b><br><br></font>
</p>
<table border="1" cols="2" cellpadding="3" cellspacing="0">
<tr><td bgcolor="#999999"><font color="blue"><b>Nickname</b></font></td><td bgcolor="#999999"><font color="blue"><b>Real name</b></font></td></tr>
<?
 $q="select nume, numeprenume, id_user from useri where 1 order by nume asc";
 $rez=mysql_query($q);
 while($crt=mysql_fetch_array($rez)){
 ?>
 <tr><td><a href="membri.php?id=<?=$crt['id_user']?>"><font color="#CCCCCC"><b><?=$crt['nume']?></b></font></td><td><b><?=$crt['numeprenume']?></b></a></td></tr>
 <?
 }
?>
</table>
</center>
