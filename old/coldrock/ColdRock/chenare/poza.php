<?
include("../forum/e_logat.php");
$filename="../forum/imagini/".$a['id_user'];
if (file_exists($filename)) {
$size = getimagesize ($filename);
}
else $size=0;
if($size){
 $w=$size[0];
 $h=$size[1];
 print "<img src=\"".$filename."\"";
 if($w>=$h and $w>100) print " width=\"100\"";
 else if($h>$w and $h>100) print " height=\"100\"";
 print ">";
}
?>