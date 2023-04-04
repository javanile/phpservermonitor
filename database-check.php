#!/usr/bin/env php
<?php

$config = getenv('APACHE_DOCUMENT_ROOT').'/config.php';

echo file_get_contents($config);

$host = getenv('MYSQL_HOST');
$user = getenv('MYSQL_USER');
if ($user == 'root') {
    $password = getenv('MYSQL_ROOT_PASSWORD');
} else {
    $password = getenv('MYSQL_PASSWORD');
}
$port = 3306;

do {
    @mysqli_connect($host, $user, $password, '', $port);
    $error = @mysqli_connect_errno();
    sleep(2);
} while ($error && $error >= 2000);
