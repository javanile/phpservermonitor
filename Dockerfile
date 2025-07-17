FROM scavin/phpservermonitor:3.3.2

RUN apt-get update
RUN apt-get install -y libzip-dev
RUN apt-get clean -y
RUN rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install zip

RUN rm /usr/local/bin/maria-wait.sh

RUN sed 's#/usr/local/bin/maria-wait.sh#/usr/local/bin/database-check.php#g' -i /usr/local/bin/docker-entrypoint.sh
RUN sed '$ i\    require_once __DIR__ . "/backup.cron.php";' -i /var/www/html/cron/status.cron.php

RUN composer require ifsnop/mysqldump-php --prefer-dist

COPY database-check.php /usr/local/bin/
COPY backup.cron.php /var/www/html/cron/

ENV MYSQL_USER root
ENV MYSQL_HOST mysql
ENV MYSQL_PASSWORD secret
