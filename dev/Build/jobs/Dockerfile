FROM debian:stretch

LABEL maintainer="software@editricetoni.it"

RUN apt-get update \
    && apt-get -y install cron curl s3cmd
    
RUN mkdir -p /root/utils \
    && mkdir -p /root/db_backups
    
COPY /db/backup_db.sh /root/utils

RUN chmod 0744 /root/utils/backup_db.sh

COPY /db/backup_db_cron /etc/cron.d/backup_db_cron
COPY db/s3cmd.conf /root/.s3cfg

RUN chmod 0644 /etc/cron.d/backup_db_cron
RUN crontab /etc/cron.d/backup_db_cron
RUN touch /var/log/db_backup_cron.log
RUN s3cmd -c /root/.s3cfg sync /root/db_backups s3://daphne-backups

CMD cron && tail -f /var/log/db_backup_cron.log