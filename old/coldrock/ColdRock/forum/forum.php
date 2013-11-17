<?
session_start();
if($_SESSION['logged']!=1) header("location: login.php");
else include("general.php");
?>