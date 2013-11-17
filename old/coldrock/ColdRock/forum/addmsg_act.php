<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("conectare.php");
$titlu=trim($_POST['titlu']);
$continut=trim($_POST['continut']);
if($continut && $titlu){
$acum=getdate();
$data=$acum['year']."-".$acum['mon']."-".$acum['mday']." ".$acum['hours'].":".$acum['minutes'].":".$acum['seconds'];
$q="insert into mesaje (id_topic,id_user,titlu,continut,data,lastpost) values('".$_SESSION['id_topic']."','".$_SESSION['id_user']."','".$titlu."','".$continut."','".$data."','".$data."');";
mysql_query($q);
$q="update topic set lastpost='".$data."' where id_topic='".$_SESSION['id_topic']."';";
mysql_query($q);
}
header("location: ".$_SESSION['adresa']);
?>
