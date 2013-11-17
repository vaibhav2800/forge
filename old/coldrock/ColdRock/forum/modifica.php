<?
session_start();
if(!$_SESSION['logged']) header("location: forum.php");
include("conectare.php");
$q="update useri set numeprenume='".$_POST['NumePrenume']."', mail='".$_POST['mail']."'";
if($_POST['parola']!="") $q=$q.", parola='".$_POST['parola']."'";
$q=$q." where id_user='".$_SESSION['id_user']."' limit 1;";
mysql_query($q);
header("location: contul_meu.php");


$uploaddir = 'imagini/';
	if($_FILES['imagine']['size']>204800){
	print "<body bgcolor=\"#000000\" text=\"#FFFF00\">";
 	print "<pre>";
 	print "Fisier imagine prea mare. <br>";
 	print "</pre>";
 	$over=1;
	}
if ($_FILES['imagine']['size']!=0 && !(move_uploaded_file($_FILES['imagine']['tmp_name'], $uploaddir.$_SESSION['id_user'])))
{
	print "<body bgcolor=\"#000000\" text=\"#FFFF00\">";
	print "<pre>";
    print "Eroare la upload-ul imaginii:\n";
    switch($_FILES['imagine']['error']){
	case 1: print "Fisier prea mare!\n";break;
	case 2: print "Fisier prea mare!\n";break;
	case 3: print "Fisier uploadat doar partial!\n";break;
	case 4: print "Nu a fost uploadat nici un fisier.\n";break;
	};
	print "</pre>";
	$over=1;
}


	if(!$over) header("location: contul_meu.php");
	else{
?>
	<body bgcolor="#000000" text="#FFFF00">
	<font size=3>
	Your profile has been updated, but there was a problem with the image file.<br />
	(The file was probably too big, plese try again with a file under 200KB)<br />
	<a href="contul_meu.php">Return to profile page</a> 
	<a href="forum.php">Return to forum</a>
	</font>
<?
	}	//de la else din linia 37
?>
