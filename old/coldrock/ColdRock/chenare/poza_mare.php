<?
include("../forum/e_logat.php");
$filename="../forum/imagini/".$a['id_user'];
if (file_exists($filename)) {
$size = getimagesize ($filename);
}
else $size=0;
if($size){
 print "<img src=\"".$filename."\">";
}
?>