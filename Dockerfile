FROM phpservermonitor/phpservermon

COPY database-check.php /usr/local/bin/

RUN rm /usr/local/bin/maria-wait.sh && \
    sed 's#/usr/local/bin/maria-wait.sh#/usr/local/bin/database-check.php#g' -i /usr/local/bin/docker-entrypoint.sh && cat /usr/local/bin/docker-entrypoint.sh

ENV MYSQL_USER root
ENV MYSQL_HOST mysql
ENV MYSQL_PASSWORD secret
