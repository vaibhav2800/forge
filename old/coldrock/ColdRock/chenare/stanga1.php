<?
 session_start();
 if(!$_SESSION['logged']) header("location:../forum/login.php");
 include("../forum/conectare.php");
?>

<div style="width:120px; background-color:#f9f1e7; padding: 4px; border:solid #632415 1px" align="left">
<font color="#000000">
Newest members:<br></font><br><b>
<?
 $q="select nume,id_user from useri order by id_user desc limit 0,5;";
 $rez=mysql_query($q);
while($crt=mysql_fetch_array($rez)){
  ?>
  <a href="../forum/membri.php?id=<?=$crt[id_user]?>"> <font color="#003333"><?=$crt[nume]?></font><br>
  <?				//link=ul de mai sus se inchide cu </a> dupa ce pun imaginea
  
$filename="../forum/imagini/".$crt['id_user'];
if (file_exists($filename)) {
$size = getimagesize ($filename);
}
else $size=0;
if($size){
 $w=$size[0];
 $h=$size[1];
 print "<br><img src=\"".$filename."\"";
 if($w>=$h and $w>100) print " width=\"100\"";
 else if($h>$w and $h>100) print " height=\"100\"";
 print ">";
}
print "</a>"; //am inchis link=ul care include numele si imaginea
print "<br><hr color=#003366>";
  
} //se inchide WHILE de mai sus
?>
</font>
</b>
<br><center>
<a href="lista_membri.php"><font color="#006699" face="Arial, Helvetica, sans-serif"><b>Members list</b></font></a>
</center>
</div>
