<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("conectare.php");
?>
<html>
<head><title>Profile update</title></head>
<?
include("../chenare/page_top.html");
?>

<script type="text/javascript">
    function verif_modif(){
	 x=document.myForm;
	 if(x.parola.value!=x.parola2.value) {alert("Passwords don't match!"); return false;}
	 if((x.NumePrenume.value)=="" || x.mail.value=="") {alert("Please fill all fields!");return false;}
	 return true;
	}
</script>

<body bgcolor="#000000" text="#CCCCCC">
<br><br>

<center>
<style type="text/css">
table {font-family: Verdana, Arial, sans-serif; font-size:14px;}
</style>

<?
 $q="select * from useri where id_user='".$_SESSION['id_user']."';";
 $rez=mysql_query($q);
 if(mysql_num_rows($rez)!=1) print "We have encountered a database error. We are sorry for the inconvenience.";
 else{		//se inchide la finalul fisierului
 $a=mysql_fetch_array($rez);
?>
<table border="0" cellpadding="3" cellspacing="0">
<tr>

<td width="300" valign="top"><br>
 <center>
 Current data:<br><br>
 <table border="1" cols="2" cellspacing="0" cellpadding="10">
 <tr><td>Nickname</td><td><?=$a['nume']?></td></tr>
 <tr><td>Real Name</td><td><?=$a['numeprenume']?></td></tr>
 <tr><td>E-mail address</td><td><?=$a['mail']?></td></tr>
 <tr><td>Password</td><td><?=$a['parola']?></td></tr>
 </table>
 <br>
 <a href="forum.php"><font color="#0099FF"><b>Inapoi in FORUM</b></font></a>
 </center>
</td>

<td width="300" valign="top"><br>
 <center>New data:<br><br>
 <table border="1" cols="2" cellspacing="0" cellpadding="10">
  <form enctype="multipart/form-data" action="modifica.php" method="post" onSubmit="return verif_modif()" name="myForm">
 <tr><td>Nickname</td><td><?=$a['nume']?></td></tr>
 <tr><td>Real name</td><td><input name="NumePrenume" type="text" maxlength="50" value="<?=$a['numeprenume']?>"></td></tr>
 <tr><td>E-mail address</td><td><input name="mail" type="text" maxlength="50" value="<?=$a['mail']?>"></td></tr>
 <tr><td colspan="2">To change the password, complete the fields below:</td></tr>
 <tr><td>New password</td><td><input name="parola" type="password" maxlength="30"></td></tr>
 <tr><td>Confirm new password</td><td><input name="parola2" type="password" maxlength="30"></td></tr>
 <tr><td colspan="2">
  Your current picture (if any) is below.<br>You can upload a different one here:<br>
  <input type="hidden" name="MAX_FILE_SIZE" value="204800">
  <input name="imagine" type="file">
  <br />File size must not exceed 200kB.
 </td></tr>
 <tr><td colspan="2" align="center"><input type="submit" value="Modifica!"></td></tr>
  </form>
 </table>
 <br>
 </center>
</td>
</tr>
</table>

<?
$a['id_user']=$_SESSION['id_user'];
include("../chenare/poza_mare.php");
?>

</center></body>
</html>
<?
} //de la else din lnia 21
?>
