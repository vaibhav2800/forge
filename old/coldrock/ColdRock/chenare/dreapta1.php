<div style="width:125px; background-color:#f9f1e7; padding: 4px; border:solid #632415 1px" align="center">
<font color="#000000">
Logged in as:<br>
<?
 //folosesc nume de variabile dreapta1_variabila pentru a nu intra in conflict cu variab din 
 //fisierele in care includ fisierul curent, dreapta1.php
 $dr1_q="select nume,id_user from useri where id_user='".$_SESSION['id_user']."';";
 $dr1_rez=mysql_query($dr1_q);
 $dr1_nrez=mysql_fetch_array($dr1_rez);
 $dr1_nume=$dr1_nrez['nume'];
 ?>
  <a href="membri.php?id=<?=$_SESSION[id_user]?>"> <b><font color="#003333"><?=$dr1_nume?></font></b><br /><br />
 <?
  //pentru poza.php folosesc $a['id_user']
  $a['id_user']=$_SESSION['id_user'];
  include("poza.php");
  ?>
  </a><br /><br />
 
<a href="contul_meu.php"><font color=#003333 face="Courier New, Courier, mono">Change profile</font></a><br />
<a href="view_privmsg.php"><font color=#003333 face="Courier New, Courier, mono">Priv. msg.</font></a><br />
<a href="privmsg_report.php"><font color=#003333 face="Courier New, Courier, mono">Priv. msg. report</font></a><br />
<a href="logout.php"><font color=#003333 face="Courier New, Courier, mono">Logout</font></a>
</font>
</div>
