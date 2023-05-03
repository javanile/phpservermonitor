<?php

namespace {

    use psm\Router;
    use Ifsnop\Mysqldump as IMysqldump;

    require_once __DIR__ . '/../src/bootstrap.php';

    if (!psm_get_conf('email_smtp')) {
        return;
    }

    if (time() - psm_get_conf('last_backup_sent') < 604800) {
        return;
    }

    $dsn = 'mysql:host='.PSM_DB_HOST.';dbname='.PSM_DB_NAME;
    $file = 'dump';
    $sql_file = '/tmp/'.$file.'.sql';

    try {
        $dump = new IMysqldump\Mysqldump($dsn, PSM_DB_USER, PSM_DB_PASS);
        $dump->start($sql_file);
    } catch (\Exception $e) {
        echo 'mysqldump-php error: ' . $e->getMessage();
    }

    $zip_file = '/tmp/'.$file.'.zip';
    $zip = new ZipArchive();
    if ($zip->open($zip_file, ZipArchive::CREATE) !== true) {
        exit("cannot open <$zip_file>\n");
    }
    $zip->addFile($sql_file, $file.'.sql');
    $zip->close();

    $user = $router->getService('user')->getUser(1);

    $mail = psm_build_mail();
    $mail->Subject = 'Backup';
    $mail->Priority = 1;
    $body = 'Backup';
    $mail->Body = $body;
    $mail->AltBody = $body;
    $mail->AddAddress($user->email, $user->name);
    $mail->AddAttachment($zip_file);
    $mail->Send();
    $mail->ClearAddresses();

    psm_update_conf('last_backup_sent', time());
}
