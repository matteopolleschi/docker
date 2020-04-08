FROM debian:stretch

LABEL maintainer="software@editricetoni.it"

RUN apt-get update \
    && apt-get -y install \
        cron \
        curl

RUN mkdir -p /home/utils \
    && mkdir -p db_backups
    
COPY /db/backup_db.sh /home/utils

RUN chmod 0744 /home/utils/backup_db.sh

COPY /db/backup_db_cron /etc/cron.d/backup_db_cron

RUN chmod 0644 /etc/cron.d/backup_db_cron
RUN crontab /etc/cron.d/backup_db_cron
RUN touch /var/log/db_backup_cron.log

CMD cron && tail -f /var/log/db_backup_cron.log