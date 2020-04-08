FROM debian:stretch

LABEL maintainer="software@editricetoni.it"

RUN apt-get update \
<<<<<<< HEAD
    && apt-get -y install \
        cron \
        curl

RUN mkdir -p /home/utils \
    && mkdir -p db_backups
    
COPY /db/backup_db.sh /home/utils

RUN chmod 0744 /home/utils/backup_db.sh

COPY /db/backup_db_cron /etc/cron.d/backup_db_cron
=======
    && apt-get -y install cron curl s3cmd
    
RUN mkdir -p /root/utils \
    && mkdir -p /root/db_backups
    
COPY /db/backup_db.sh /root/utils

RUN chmod 0744 /root/utils/backup_db.sh

COPY /db/backup_db_cron /etc/cron.d/backup_db_cron
COPY /db/env/s3cmd.conf /root/.s3cfg
>>>>>>> 70b553fd9dfe20c2cc9b88548a9c0dd413c628f8

RUN chmod 0644 /etc/cron.d/backup_db_cron
RUN crontab /etc/cron.d/backup_db_cron
RUN touch /var/log/db_backup_cron.log
<<<<<<< HEAD
=======
RUN s3cmd -c /root/.s3cfg sync /root/db_backups s3://daphne-backups
>>>>>>> 70b553fd9dfe20c2cc9b88548a9c0dd413c628f8

CMD cron && tail -f /var/log/db_backup_cron.log