<?php

require __DIR__ . '/src/bootstrap.php';

if (!psm_get_conf('email_smtp')) {
    die("No STMP settings");
}

echo "OK";
