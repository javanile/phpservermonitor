<?php

require __DIR__ . '/src/bootstrap.php';

function error($message) {
	http_response_code(500);
	echo "$message\n";
	exit;

}

if (!psm_get_conf('email_smtp')) {
    error("No STMP settings");
}

echo "OK!\n";
