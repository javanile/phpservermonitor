FROM phpservermonitor/phpservermon

RUN apt-get update && \
    apt-get install -y libzip-dev && \
    docker-php-ext-install zip && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm /usr/local/bin/maria-wait.sh && \
    sed 's#/usr/local/bin/maria-wait.sh#/usr/local/bin/database-check.php#g' -i /usr/local/bin/docker-entrypoint.sh && \
    sed '$ i\    require_once __DIR__ . "/backup.cron.php";' -i /var/www/html/cron/status.cron.php && \
    composer require ifsnop/mysqldump-php --prefer-dist

COPY database-check.php /usr/local/bin/
COPY backup.cron.php /var/www/html/cron/

ENV MYSQL_USER root
ENV MYSQL_HOST mysql
ENV MYSQL_PASSWORD secret
