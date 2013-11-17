<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("conectare.php");
$continut=trim($_POST['continut']);
if($continut){
$acum=getdate();
$data=$acum['year']."-".$acum['mon']."-".$acum['mday']." ".$acum['hours'].":".$acum['minutes'].":".$acum['seconds'];
$q="insert into reply (id_user,id_mesaj,continut,data) values('".$_SESSION['id_user']."','".$_SESSION['id_mesaj']."','".$continut."','".$data."');";
mysql_query($q);
$q="update mesaje set lastpost='".$data."' where id_mesaj='".$_SESSION["id_mesaj"]."';";
mysql_query($q);
$q="update topic set lastpost='".$data."' where id_topic='".$_SESSION['id_topic']."';";
mysql_query($q);
}
header("location: ".$_SESSION['adresa']);
?>
