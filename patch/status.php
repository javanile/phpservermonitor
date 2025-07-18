<?php

require __DIR__ . '/src/bootstrap.php';

function error($message) {
	echo "ERROR: $message\n";
	exit;
}

if (!psm_get_conf('email_smtp')) {
    error("No STMP settings, Go to Config/Email/STMP to set it up.");
}

echo "OK!\n";
