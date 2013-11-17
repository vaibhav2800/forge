<?
 include("e_logat.php");
 include("conectare.php");
?>

<html>
<head>
<title>ColdRock - Member profile</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<style type="text/css">
table {font-family: Verdana, Arial, sans-serif; font-size:18px;}
</style>
<body bgcolor="#222222" text="#FF9933">
<?
  $id=$_GET['id'];
  $a=mysql_fetch_array(mysql_query("select * from useri where id_user='".$id."';"));
  if($a['id_user']==$id){	//daca de fapt exista acel user
?>
<!--URMEAZA DE FAPT PAGE_TOP.HTML-->
<center>
  <img src="../imagini/logo.jpg" width="909" height="129" border="0" usemap="#MapLogo"> 
  <map name="MapLogo">
  <area shape="circle" coords="450,66,82" href="../forum/forum.php">
</map>
</center>


<br /><br /><br />
<center>
<table border="1" cols="2" cellspacing="0" cellpadding="10">
<tr><td>Nickname</td><td><?=$a['nume']?></td></tr>
<tr><td>Real name</td><td><?=$a['numeprenume']?></td></tr>
<tr><td>E-mail address</td><td><?=$a['mail']?></td></tr>
</font>
</table>
<br />
<a href="sendprivmsg.php?id=<?=$id?>"><font color="#00ff00">Send private message</font></a>
<br /><br />
<?
  include("../chenare/poza_mare.php");
?>
</center>

<?
}	//de la if
else include("eroare.html");
?>
</body>
</html>
