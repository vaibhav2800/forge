<?
include("e_logat.php");
include("conectare.php");
$id = $_GET['id'];
$id_user = $_SESSION['id_user'];
$q = "delete from priv_mesg where id_msg='$id' and id_receiver='$id_user'";
mysql_query($q);
header("location: view_privmsg.php");
?>
