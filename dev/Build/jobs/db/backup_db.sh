#! /bin/bash

MASTER_PWD=admin
DATABASE=al-citofono
FORMAT=zip
BACKUP_DIR=db_backups

mkdir -p ${BACKUP_DIR}

curl --data "master_pwd=${MASTER_PWD}&name=${DATABASE}&backup_format=${FORMAT}" \
    -o ${BACKUP_DIR}/${DATABASE}.$(date +%F)-$(date +%T).zip  \
    https://appa-messina.al-citofono.it/web/database/backup

# s3cmd put -r db_backups s3://daphne-backups/ubuntudoo/
