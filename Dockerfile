FROM php:7.4-apache
# MAINTAINER Austin St. Aubin <austinsaintaubin@gmail.com>

# Build Environment Variables
ENV VERSION 3.5.2
ENV URL https://github.com/phpservermon/phpservermon/archive/v${VERSION}.tar.gz

# Install Base
RUN apt-get update

# Install & Setup Dependencies
RUN set -ex; \
    apt-get install -y curl iputils-ping; \
    apt-get install -y zip unzip git; \
    #docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-webp-dir=/usr --with-png-dir=/usr --with-xpm-dir=/usr; \
    docker-php-ext-install pdo pdo_mysql mysqli sockets; \
    apt-get clean -y; \
    rm -rf /var/lib/apt/lists/*; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Expose Ports
EXPOSE 80

# Apache Document Root
ENV APACHE_DOCUMENT_ROOT /var/www/html
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# User Environment Variables
ENV PSM_REFRESH_RATE_SECONDS 90
ENV PSM_AUTO_CONFIGURE true
ENV PSM_PHP_DEBUG false
ENV MYSQL_HOST database
ENV MYSQL_USER phpservermonitor
ENV MYSQL_PASSWORD YOUR_PASSWORD
ENV MYSQL_DATABASE phpservermonitor
ENV MYSQL_DATABASE_PREFIX psm_

# Time Zone
ENV PHP_TIME_ZONE 'Europe/Amsterdam'
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN sed -i 's/;date.timezone =/date.timezone = "${PHP_TIME_ZONE}"/g' "$PHP_INI_DIR/php.ini"
# RUN php -i | grep -i error

# Webserver Run User
ENV APACHE_RUN_USER www-data

# Persistent Sessions
RUN mkdir '/sessions'; \
    chown ${APACHE_RUN_USER}:www-data '/sessions'; \
    sed -i 's/;session.save_path\s*=.*/session.save_path = "\/sessions"/g' "$PHP_INI_DIR/php.ini"; \
    cat "$PHP_INI_DIR/php.ini" | grep 'session.save_path'
VOLUME /sessions

# Extract Repo HTML Files
RUN set -ex; \
  cd /tmp; \
  rm -rf ${APACHE_DOCUMENT_ROOT}/*; \
  curl --output phpservermonitor.tar.gz --location $URL; \
  tar -xvf phpservermonitor.tar.gz --strip-components=1 -C ${APACHE_DOCUMENT_ROOT}/; \
  cd ${APACHE_DOCUMENT_ROOT}
#   chown -R ${APACHE_RUN_USER}:www-data /var/www
#   find /var/www -type d -exec chmod 750 {} \; ; \
#   find /var/www -type f -exec chmod 640 {} \;

# Configuration
# VOLUME ${APACHE_DOCUMENT_ROOT}/config.php
RUN touch ${APACHE_DOCUMENT_ROOT}/config.php; \
    chmod 0777 ${APACHE_DOCUMENT_ROOT}/config.php

# Composer install dependencies
RUN composer install --no-dev -o

# Add Entrypoint & Start Commands
COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod u+rwx /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]

RUN apt-get update
RUN apt-get install -y libzip-dev
RUN apt-get clean -y
RUN rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install zip


RUN sed 's#/usr/local/bin/maria-wait.sh#/usr/local/bin/database-check.php#g' -i /usr/local/bin/docker-entrypoint.sh
RUN sed '$ i\    require_once __DIR__ . "/backup.cron.php";' -i /var/www/html/cron/status.cron.php

RUN composer require ifsnop/mysqldump-php --prefer-dist
RUN composer require dragonmantank/cron-expression --prefer-dist

COPY patch/database-check.php /usr/local/bin/
COPY patch/backup.cron.php /var/www/html/cron/
COPY patch/status.php /var/www/html/
COPY patch/debug.php /var/www/html/
COPY patch/install-queries.txt /var/www/html/patch/
COPY patch/install-admin-user-form.txt /var/www/html/patch/
COPY patch/install-admin-user-env.txt /var/www/html/patch/

# docker compose exec app cat /var/www/html/src/psm/Util/Install/Installer.php > debug.php
RUN sed -i '190r /var/www/html/patch/install-queries.txt' /var/www/html/src/psm/Util/Install/Installer.php
# docker compose exec app cat /var/www/html/src/templates/default/module/install/config_new_user.tpl.html > debug.html
RUN sed -i '9r /var/www/html/patch/install-admin-user-form.txt' /var/www/html/src/templates/default/module/install/config_new_user.tpl.html
# docker compose exec app cat /var/www/html/src/psm/Module/Install/Controller/InstallController.php > debug.php
RUN sed -i '262r /var/www/html/patch/install-admin-user-env.txt' /var/www/html/src/psm/Module/Install/Controller/InstallController.php

ENV MYSQL_USER root
ENV MYSQL_HOST mysql
ENV MYSQL_PASSWORD secret

ENV PSM_ADMIN_USER admin
ENV PSM_ADMIN_PASSWORD admin
ENV PSM_ADMIN_EMAIL admin@admin.com
