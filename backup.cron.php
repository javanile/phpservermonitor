<?php

namespace {
    use psm\Router;

    require_once __DIR__ . '/../src/bootstrap.php';

    $email_smtp = psm_get_conf('email_smtp');

    if (empty($email_smtp)) {
        return;
    }

    $last_backup_sent = psm_get_conf('last_backup_sent');
    var_dump($last_backup_sent);
    $delta = time() - $last_backup_sent;
    var_dump($delta);
    if (time() - $last_backup_sent < 100) {
        return;
    }

    echo "Start!\n";

    use Ifsnop\Mysqldump as IMysqldump;

    try {
        $dsn = 'mysql:host='.PSM_DB_HOST.';dbname='.PSM_DB_NAME;
        $file = 'dump';
        $sql_file = '/tmp/'.$file.'.sql';
        $dump = new IMysqldump\Mysqldump($dsn, PSM_DB_USER, PSM_DB_PASS);
        $dump->start($sql_file);

        $zip_file = '/tmp/'.$file.'.zip';
        echo "A\n";
        $zip = new ZipArchive();
        echo "B\n";
        if ($zip->open($zip_file, ZipArchive::CREATE) !== true) {
            exit("cannot open <$zip_file>\n");
        }
        $zip->addFile($sql_file, $file.'.sql');
        echo "numfiles: " . $zip->numFiles . "\n";
        echo "status:" . $zip->status . "\n";
        $zip->close();

        $mail = psm_build_mail();
        $mail->Subject = 'Backup';
        $mail->Priority = 1;
        $body = 'Backup';
        $mail->Body = $body;
        $mail->AltBody = $body;
        $mail->AddAddress('info.francescobianco@gmail.com', 'Francesco Bianco');
        $mail->AddAttachment($zip_file);
        $mail->Send();
        $mail->ClearAddresses();

        psm_update_conf('last_backup_sent', time());
    } catch (\Exception $e) {
        echo 'mysqldump-php error: ' . $e->getMessage();
    }
}
