<?
session_start();
include("conectare.php");
$NumePrenume=trim($_POST['NumePrenume']);
$mail=trim($_POST['mail']);
$nume=trim($_POST['nume']);
$parola=$_POST['parola'];
if($NumePrenume!="" && $mail!="" && $nume!="" && $parola!=""){
$rez=mysql_query("Select nume from useri where nume='".$nume."';");
	if(mysql_num_rows($rez)!=0){
	print "<body bgcolor=\"#000000\" text=\"#FFFF00\">";
	print "Please choose another username. This one is in use.<br>";
	print '<a href="new_user.html"> <font color=\"#CCCCCC\">Resubmit data </a>';
	}
	else{
	$q="insert into useri (numeprenume,mail,nume,parola) values('".$NumePrenume."','".$mail."','".$nume."','".$parola."');";
	mysql_query($q);
	$resursa=mysql_query("select * from useri where nume='".$nume."';");
	$rez=mysql_fetch_array($resursa);
	$_SESSION['nume']=$nume;
	$_SESSION['logged']=1;
	$_SESSION['id_user']=$rez['id_user'];
	
	$uploaddir = 'imagini/';
	if($_FILES['imagine']['size']>204800){
	print "<body bgcolor=\"#000000\" text=\"#FFFF00\">";
 	print "<pre>";
 	print "Image file is too large. <br>";
 	print "</pre>";
 	$over=1;
	}
if ($_FILES['imagine']['size']!=0 && !(move_uploaded_file($_FILES['imagine']['tmp_name'], $uploaddir.$_SESSION['id_user'])))
{
	print "<body bgcolor=\"#000000\" text=\"#FFFF00\">";
	print "<pre>";
    print "Error on image upload:\n";$over=1;
    switch($_FILES['imagine']['error']){
	case 1: print "File too large!\n";break;
	case 2: print "File too large!\n";break;
	case 3: print "File has only been partially uploaded!\n";break;
	case 4: print "No file uploaded.\n";break;
	};
	print "</pre>";
	$over=1;
}


	if(!$over) header("location: forum.php");
	else print "<body bgcolor=\"#000000\" text=\"#FFFF00\">Retry uploading an image in the <i>personal data</i> section.<br> <a href=\"forum.php\">Proceed to forum</a>";
	
}	//else din linia 15
}	//if din linia 9
else{
print "<body bgcolor=\"#000000\" text=\"#FFFF00\">";
print "Incorrect data.";
print '<a href="new_user.html"> Resubmit data </a>';
}
?>
