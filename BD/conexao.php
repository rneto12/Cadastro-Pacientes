<?php
$utf8 = header("Content-Type: text/html; charset=utf-8");
$link = new mysqli('db','cad','cad','db_clientes');
// Caso algo tenha dado errado, exibe uma mensagem de erro
if (mysqli_connect_errno()) trigger_error(mysqli_connect_error());

$link->set_charset('utf8');
?>