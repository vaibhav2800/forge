<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
$titlu=trim($_POST['titlu']);
$descriere=trim($_POST['descriere']);
if($titlu && $descriere){
include("conectare.php");
$acum=getdate();
$data=$acum['year']."-".$acum['mon']."-".$acum['mday']." ".$acum['hours'].":".$acum['minutes'].":".$acum['seconds'];
$q="insert into topic (id_user,titlu,descriere,data,lastpost) values('".$_SESSION['id_user']."','".$titlu."','".$descriere."','".$data."','".$data."');";
mysql_query($q);
}
header("location: forum.php");
?>
