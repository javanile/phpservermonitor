<?php

namespace {

    use psm\Router;
    use Ifsnop\Mysqldump as IMysqldump;
	use Cron\CronExpression;

    require_once __DIR__ . '/../src/bootstrap.php';

    if (!psm_get_conf('email_smtp')) {
        return;
    }

    $backupInfo = json_decode(psm_get_conf('backup_info'), true) ?: [];

    if (isset($backupInfo['next']) && $backupInfo['next'] < time()) {
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

	$backupInfo['sql_size'] = filesize($sql_file) ?: 0;

    $zip_file = '/tmp/'.$file.'.zip';
    $zip = new ZipArchive();
    if ($zip->open($zip_file, ZipArchive::CREATE) !== true) {
        exit("cannot open <$zip_file>\n");
    }
    $zip->addFile($sql_file, $file.'.sql');
    $zip->close();

	$backupInfo['zip_size'] = filesize($zip_file) ?: 0;

    $user = $router->getService('user')->getUser(1);

    $mail = psm_build_mail();
    $mail->Subject = 'Backup';
    $mail->Priority = 1;
    $body = 'Backup';
    $mail->Body = $body;
    $mail->AltBody = $body;
    $mail->AddAddress($user->email, $user->name);
    $mail->AddAttachment($zip_file);
    $backupInfo["sent"] = $mail->Send();
    $mail->ClearAddresses();

	$backupSchedule = trim(getenv('PSM_BACKUP_SCHEDULE'), " '\"\t\n\r\0\x0B") ?: '0 0 * * *';
	$backupCron = CronExpression::factory($backupSchedule);
	$backupInfo['next'] = $backupCron->getNextRunDate()->getTimestamp();

    psm_update_conf('backup_info', json_encode($backupInfo));
}
