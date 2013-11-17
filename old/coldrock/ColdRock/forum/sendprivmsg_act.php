<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("conectare.php");
$continut=trim($_POST['continut']);
if($continut){
$acum=getdate();
$data=$acum['year']."-".$acum['mon']."-".$acum['mday']." ".$acum['hours'].":".$acum['minutes'].":".$acum['seconds'];
$q="insert into priv_mesg (id_sender,id_receiver,contents,senddate) values('".$_SESSION['id_user']."','".$_SESSION['id_receiver']."','".$continut."','".$data."');";
mysql_query($q);
}
header("location: forum.php");
?>
