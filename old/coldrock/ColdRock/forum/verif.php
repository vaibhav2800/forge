<?
session_start();
include("conectare.php");
$resursa=mysql_query("select * from useri where nume='".$_POST['nume']."' and parola='".$_POST['parola']."';");
if(mysql_num_rows($resursa)!=1){
	print '<body bgcolor="#000000" text="#FFFF00"><font size="5">';
	print "Incorrect data <br>";
	print '<a href="login.php"> <font color="#FFCC00">Resubmit data </font></a>';
}
else{
 $rez=mysql_fetch_array($resursa);
 $_SESSION['id_user']=$rez['id_user'];
 $_SESSION['nume']=$rez['nume'];
 $_SESSION['logged']=1;
 header("location: forum.php");
}
?>
