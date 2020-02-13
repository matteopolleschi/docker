#!/bin/bash
#
# Odoo ERP deployment script 
# Version: 0.1-beta
#
# Copyright (c) 2019 Sergey Kaimin (serge.kaimin@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# 
# TODO:
#   - production, staging, and development enviroment
#   - cloud backup
#   - unit testing
#

# Config file sets default values. Check to be sure config file is in .dockerignore to secure installation
# var1="default value for var1"
# var1="default value for var2"
CONFIG_FILE=.odoo.config
CURRENT_PATH=$(pwd)
LOGFILE=$(pwd)/.logfile

# set variables
START_BACKUP=0
START_RESTORE=0
START_POSTGRES=0

#log to screen and logfile
#  $1 text
#  $2 parameters for echo
#  $3 color
log() {
  echo $1 | tee -a $LOGFILE
}

backup() {

  logfile="${NOW}-${database}-backup.log"

mkdir -p $HOME/backup
cd $HOME/backup
echo "BACKUP: DATABASE = $database, TIME = $NOW"
read -s -p "Enter DB Password for user '$USER': " db_password
echo

if ! PGPASSWORD="$db_password" /usr/bin/psql -h $HOST -U "$USER" -l -F'|' -A "template1" | grep "|$USER|" | cut -d'|' -f1 | egrep -q "^$database\$"; then
    echo "ERROR: Database '$database' not found for user '$USER'"
    exit 2
fi

if [ ! -d "$HOME/$FILESTORE/$database" ]; then
    echo "ERROR: Filestore '$HOME/$FILESTORE/$database' not found"
    exit 3
fi

echo -n "Backup database: $database ... "
PGPASSWORD="$db_password" /usr/bin/pg_dump -Fc -v -U "$USER" --host $HOST -f "${NOW}-${database}.dump" "$database" >> $LOGFILE 2>&1
error=$?; if [ $error -eq 0 ]; then echo "OK"; else echo "ERROR: $error"; fi

echo -n "Backup filestore: $FILESTORE/$database ... "
/bin/tar -czf "${NOW}-${database}.tar.gz" -C $HOME "$FILESTORE/$database" >> $LOGFILE 2>&1
error=$?
if [ $error -eq 0 ]; then echo "OK"; else echo "ERROR: $error"; fi

}

restore() {
  exit 0
}

# Start postgresql container
#   - use parameters from configuration file
psql_start() {
  echo -n "Starting postgresql container [$PSQL_CONTAINER]: "
  #check if bysybox exists
  mkdir -p postgress-data
  docker run -d \
    -p $PSQL_PORT \
    -e POSTGRES_DB=$PSQL_DB \
    -e POSTGRES_USER=$PSQL_USER \
    -e POSTGRES_PASSWORD=$PSQL_PASSWORD \
    --name $PSQL_CONTAINER \
    -v $(pwd)/postgress-data/:/var/lib/postgresql/data \
    $PSQL_IMAGE
  # timeout
  # check if container started

  #docker exec -i db psql -U odoo -d odoo12 < ../backup/backup_all.sql

}

psql_stop() {
  echo -n "Stop postgresql container: "
  docker stop $PSQL_CONTAINER
}

psql_rm() {
  echo -n "Remove postgresql container: "
  docker rm $PSQL_CONTAINER
}

# Start postgress container procedure
start_postgres() {
  if [ $PSQL_BLOCK == "TRUE" ]; then
    echo "Not allowed by configuration start and stop database for this container. Check PSQL_BLOCK parameter"
    exit 1
  else
    # check if docker container with name $POSTGRES_CONTAINER listed by docker ps 
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${PSQL_CONTAINER}\$"; then
      # avalable statuses: created, restarting, running, removing, paused, exited, or dead
      # is container exited?
      if docker ps -a -f status=exited --format '{{.Names}}' | grep -Eq "^${PSQL_CONTAINER}\$"; then
        echo "Current status is: $PSQL_CONTAINER container exited."
        psql_rm
        psql_start
      else
        # is container running?
        if docker ps -a -f status=running --format '{{.Names}}' | grep -Eq "^${PSQL_CONTAINER}\$";  then
          tput setaf 1; echo "Container $PSQL_CONTAINER is running now."
          tput setaf 7;
          docker ps
          tput setaf 1;  echo -n "Stop container before starting. "
          tput setaf 2;  echo "Command is: odoo-docker.sh -p stop"
          tput setaf 7;
        
          #psql_stop #docker stop $PSQL_CONTAINER
          #psql_rm #docker rm $PSQL_CONTAINER
          #psql_start
          #docker stop db
          #docker rm <name>
        else
          # is container paused?
          if docker ps -a -f status=paused --format '{{.Names}}' | grep -Eq "^${PSQL_CONTAINER}\$";  then
            echo "Container $PSQL_CONTAINER is paused now."
            #docker stop db
            #docker rm <name>
          fi
        fi
      fi
      # run your container
      #psql_start
      #docker run -d --name <name> my-docker-image
    else
      echo 'Container does not exist. Did not removed old, and start new instance.'
      psql_start
    fi
  fi
}

show_odoo_ip() {
  IP=$(echo $(hostname -I) | cut -d' ' -f 1)
  echo "Odoo is running on:"
  tput setaf 2; echo "http://$IP:$ODOO_PORT/"; tput setaf 7;
}

start_odoo() {
  echo -n "Starting odoo container [$ODOO_CONTAINER]: "
  odoo_start
  show_odoo_ip
  docker ps
}

odoo_prebuild() {
  log "Prebuilding addons library"
  (cd Build && ./run_before_image_creation.sh 2>&1 | tee $LOGFILE )
  #$CURRENT_PATH/run_before_image_creation.sh
  #cd ..
}

odoo_build() {
  log "Bulding Odoo's image: $ODOO_IMAGE"
  #docker build $ODOO_IMAGE
  log "Build filestore container: $ODOO_FILESTORE"
  docker rm $ODOO_FILESTORE
  mkdir -p $CURRENT_PATH/filestore
  chmod -R a+rwx $CURRENT_PATH/filestore
  docker create \
        -v $CURRENT_PATH/filestore:/var/lib/odoo/filestore \
        --name $ODOO_FILESTORE \
        busybox 2>&1 | tee $LOGFILE

  cd Build
  log -n "Building directory is: "
  pwd
  mkdir -p addons
  #20190108
  log "Odoo version: $ODOO_VERSION"
  log "Odoo release: $ODOO_RELEASE"
  # save version and release to file
  rm -rf Build/.odoo.version || true
  eval "echo $ODOO_VERSION" > $CURRENT_PATH/Build/.odoo.version
  rm -rf Build/.odoo.release || true 
  eval "echo $ODOO_RELEASE" > $CURRENT_PATH/Build/.odoo.release
  
  docker build \
    --no-cache \
    --build-arg ODOO_VERSION=$ODOO_VERSION \
    --build-arg ODOO_RELEASE=$ODOO_RELEASE \
    -t $ODOO_IMAGE \
    . 2>&1 | tee $LOGFILE
  cd ..
  exit 0
}

odoo_stop() {
  echo "Stop odoo container"
  docker stop $ODOO_CONTAINER
}

odoo_rm() {
  echo "Stop rm odoo container"
  docker rm $ODOO_CONTAINER
}

stop_odoo() {
   odoo_stop
   odoo_rm
}

odoo_start() {
  #if [ $ODOO_PROXY != "no_proxy" ]; then
    #docker run -d -v $(pwd):/etc/odoo -p 80:8069 --name odoo12 --link db:db -t ubuntudoo-it:12
    # check if $ODOO_CONTAINER is existing
    #-v ../filestore:/var/lib/odoo/.local/share/Odoo/filestore \
    log "Start filestore container: $ODOO_FILESTORE"
    #if [ ! "$(docker ps -q -f name=$ODOO_FILESTORE)" ]; then
    #    if [ "$(docker ps -aq -f status=exited -f name=$ODOO_FILESTORE)" ]; then
    #      # cleanup
    #      echo "cleanup container"
    #      docker rm $ODOO_FILESTORE
    #    fi
    #  # run your container
    #  #docker run -d --name <name> my-docker-image
    #fi

    docker rm $ODOO_FILESTORE
    mkdir -p $CURRENT_PATH/filestore
    chmod -R a+rwx $CURRENT_PATH/filestore
    # run of create
    docker run \
        -v $CURRENT_PATH/filestore:/var/lib/odoo/filestore \
        --name $ODOO_FILESTORE \
        busybox 2>&1 | tee $LOGFILE

    cd Build
    docker stop $ODOO_CONTAINER
    docker rm $ODOO_CONTAINER 
    docker run \
        -d \
        -v $(pwd):/etc/odoo \
        -e DB_ENV_NAME=$ODOO_DATABASE \
        --volumes-from $ODOO_FILESTORE \
        -p $ODOO_PORT:8069 \
        --name $ODOO_CONTAINER \
        --link $PSQL_CONTAINER:db \
        -t $ODOO_IMAGE \
        2>&1 | tee $LOGFILE
        # Set default database
        # python ./odoo.py --addons=addons --db-filter=db_odoo_school_management 
  echo "copy"
  docker cp $CURRENT_PATH/Build/.odoo.version $ODOO_CONTAINER:/etc/odoo/
  docker cp $CURRENT_PATH/Build/.odoo.release $ODOO_CONTAINER:/etc/odoo/
  cd $CURRENT_PATH
  #else
  #  exit 0
    #Odoo via proxy
    #docker run -d -v $(pwd):/etc/odoo -p 8069:8069 --name odoo12 --link db:db -t ubuntudoo-it:12
  #fi
}

stop_postgres() {
  if [ $PSQL_BLOCK == "TRUE" ]; then
    log "Not allowed by configuration start and stop database for this container. Check PSQL_BLOCK parameter"
    exit 1
  else
    psql_stop
    echo "List of active containers after stop"
  fi
}

status_odoo() {
  #https://webkul.com/blog/beginner-guide-odoo-clicommand-line-interface/
  docker ps |grep $ODOO_CONTAINER
  if [ "$(docker ps -q -f name=$ODOO_CONTAINER)" ]; then
    if [ "$(docker ps -aq -f status=running -f name=$ODOO_CONTAINER)" ]; then
        echo "Odoo container is running: $ODOO_CONTAINER"
        show_odoo_ip
    else
      echo "Odoo container status is not 'running': $ODOO_CONTAINER"
    fi
  else 
    echo "Odoo container is not running: $ODOO_CONTAINER"
    docker inspect $ODOO_CONTAINER
  fi
  
}

status_postgres() {
  # /sbin/service postgresql status
  # /etc/init.d/postgresql status
  #docker exec -it -u postgres db bash
  #docker exec -i $PSQL_CONTAINER "/etc/init.d/postgresql status"
  tput setaf 2; echo "Database postgresql status:"; tput setaf 7;
  docker ps -a -f status=running | grep $PSQL_CONTAINER
  docker exec -i $PSQL_CONTAINER  pg_isready 
  docker exec \
      -i $PSQL_CONTAINER \
          psql  \
             -U $PSQL_USER \
             -l
}

build_odoo() {
  #Build Postgress SQL

  log "Build filestore container: $ODOO_FILESTORE"
  docker rm $ODOO_FILESTORE
  mkdir -p $CURRENT_PATH/filestore
  chmod -R a+rwx $CURRENT_PATH/filestore
  docker create \
        -v $CURRENT_PATH/filestore:/var/lib/odoo/filestore \
        --name $ODOO_FILESTORE \
        busybox 2>&1 | tee $LOGFILE

  log "Build: $ODOO_IMAGE"
  echo `docker ps -a`

  if [ ! "$(docker ps -q -f name=`$ODOO_CONTAINER`)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=`$ODOO_CONTAINER`)" ]; then
        echo "# cleanup"
        #docker rm <name>
        exit 0
    fi
    # run your container
    docker run -d --name $ODOO_CONTAINER ODOO_IMAGE
fi
  [ ! "$(docker ps -a | grep `$ODOO_CONTAINER`)" ] && echo 
  #docker run -d --name <name> <image>
}


# migrate database 
backup_migrate() {
  # check if passed argument -f filename.tar.gz
  echo "Enter name of the file:"
  #untar to tmp
  #check what is the name
  echo "database name detected"
  echo "Enter new name of database:"
  #migrate filestore
  #migrate database

  #-n db -db addons -n filestore - to disable
  exit 0
}

#backup database to current directory, and gzip
backup_database() {
  log "Backup Odoo's postgresql: $ODOO_DATABASE"
  # save name of database and backup date
  echo "$ODOO_DATABASE" > .database
  echo "$NOW" > .backup_date

  # Check if list of excluded tables is empty, set variable $EXCL
  if [ -z "${BACKUP_EXCLUDE_TABLE}" ]; then
    log "No excluded tables configured"
    EXCLUDE_TABLES=""
  else
    log "added tables to exclude: $BACKUP_EXCLUDE_TABLE"
    EXCLUDE_TABLES="--exclude-table=$BACKUP_EXCLUDE_TABLE"
  fi

  # start backup
  docker exec \
    -u postgres \
    -e PGPASSWORD=$PSQL_PASSWORD \
    $PSQL_CONTAINER \
        pg_dump $EXCLUDE_TABLES \
            --username=$PSQL_USER \
            --create \
            --clean \
            $ODOO_DATABASE \
                > database.sql
    
    # check if additional pd_dump arguments required: https://www.postgresql.org/docs/9.1/app-pgdump.html
    #--exclude-table=table 
    #--format tar \
    #--verbose \
    gzip database.sql
    log "psql backup successfuly done"
}

#backup addons to current path, tar archive, and remove directory
backup_addons() {
  log "Backup Odoo's addons"
  docker cp $ODOO_CONTAINER:/etc/odoo/addons/ $(pwd)
  log "addons backup successfuly done"
}

backup_filestore() {
  log "Backup filestore: $BACKUP_DB"
  docker exec -u 0 $ODOO_CONTAINER \
      tar Ccf $(dirname /var/lib/odoo/filestore/$BACKUP_DB/) - $(basename /var/lib/odoo/filestore/$BACKUP_DB/) | tar Cxf $(pwd) -
  mv $BACKUP_DB/* .
  rmdir $BACKUP_DB  
  #tar -czf filestore.tar *
  # Remove temp files
  #rm -rf $BACKUP_DB
  log "Filestore backup successfuly done"
}

# check if backup directore exists, and flag process pid to file
backup_check() {
  # check of $BACKUP_PATH exists
  if [ ! -d $1 ]; then
    echo "Create directory $CURRENT_PATH/$1/tmp"
    mkdir -p $CURRENT_PATH/$1/tmp
  fi
  # Exit if previuos backup didn't ended success
  if [ -f $CURRENT_PATH/$1/tmp/.backup ]; then
    log "Check if backup is running by other process or previous backup not ended well:","-n"
    echo -n "PID:"
    cat $1/tmp/.backup
    log " Exit due to $1/tmp/.backup"
    exit 1
  fi
  # save script's pid to backup/tmp/.backup
  echo $$ > $1/tmp/.backup
}

#backup procedure for current database
backup_odoo() {
  B_PATH=$BACKUP_PATH
  B_DB=$BACKUP_DB
  if [[ -n "$1" ]]; then
    B_PATH=$1
    B_DB=$EXPORT_DB
  fi
  echo "value: $1 direcroty:$CURRENT_PATH/$B_PATH/$B_DB"
   #check if directory exists and no other backup processes are running
  backup_check $B_PATH
  # Backup database to tmp
  
  rm -rf $CURRENT_PATH/$B_PATH/tmp/db || true
  mkdir -p $CURRENT_PATH/$B_PATH/tmp/db
  cd $CURRENT_PATH/$B_PATH/tmp/db
  backup_database
  cd $CURRENT_PATH

  #Backup addons
  rm -rf $CURRENT_PATH/$B_PATH/tmp/addons/ "" true
  mkdir -p $CURRENT_PATH/$B_PATH/tmp/addons/
  cd $CURRENT_PATH/$B_PATH/tmp/
  backup_addons
  cd $CURRENT_PATH

  #read -p "Press enter to continue"

  #Backup filestore
  rm -rf $CURRENT_PATH/$B_PATH/tmp/filestore/ || true
  mkdir -p $CURRENT_PATH/$B_PATH/tmp/filestore/
  cd $CURRENT_PATH/$B_PATH/tmp/filestore/
  #echo "$ODOO_DATABASE" > .filestore
  #mkdir -p $BACKUP_PATH/$BACKUP_DB/$NOW/filesystem
  backup_filestore
  cd $CURRENT_PATH
  
  #copy release and version numbers /etc/odoo/.odoo.*
  docker cp $ODOO_CONTAINER:/etc/odoo/.odoo.version $B_PATH/tmp/
  docker cp $ODOO_CONTAINER:/etc/odoo/.odoo.release $B_PATH/tmp/

  #read -p "Press enter to continue"

  # tar tmp rchive and move to db
  log "Store odoo's archive: $CURRENT_PATH/$BACKUP_PATH/$BACKUP_DB/odoo_backup-$NOW.tar.gz"
  mkdir -p $CURRENT_PATH/$BACKUP_PATH/$BACKUP_DB
  cd $CURRENT_PATH/$B_PATH/tmp/
  tar -cz \
      --exclude="$B_PATH/tmp/.backup" \
      -f $CURRENT_PATH/$BACKUP_PATH/$BACKUP_DB/odoo_backup-$NOW.tar.gz \
      .
  cd $CURRENT_PATH
  log "Cleaning of backup directory"
  #rm -rf $BACKUP_PATH/tmp/filestore/ || true
  #rm -rf $BACKUP_PATH/tmp/addons/addons/* || true
  #rm -rf $BACKUP_PATH/tmp/db || true
  
  log "Completed system backup"
  
  #echo "Disk usage:"
  #du $BACKUP_PATH/$BACKUP_DB/
  if [ -f $B_PATH/tmp/.backup ]; then
    rm $B_PATH/tmp/.backup
  fi
}

backup_list() {
  echo "List of backups available:"
  ls -a $BACKUP_PATH/$ODOO_DATABASE/*.gz | sort -k1,1
}

restore_check() {
  # check of $BACKUP_PATH exists
  if [ ! -d restore ]; then
    echo "Create directory restore"
    mkdir -p restore/tmp
  fi

  if [ -f restore/tmp/.restore ]; then
    log "Check if restore script is running by other process or previous backup not ended well:","-n"
    cat restore/tmp/.restore
    log " Exit due to restore/tmp/.restore"
    exit 1
  fi
}

restore_procedure() {
  tar -xf $1
  du
  #rm restore/tmp/.restore || true
  #rm -rf restore/tmp/* || true
  RESTORE_DB=$(cat "db/.database")
  RESTORE_DATE=$(cat "db/.backup_date")
  log "Database to restore: $RESTORE_DB"
  log "Database date: $RESTORE_DATE"
  read -p "Are you sure? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then

    log "Start restore of database"
    cd db
    log "copy archive"
    docker cp database.sql $PSQL_CONTAINER:/
    log "import db"
    gzip -d \
      database.sql.gz 
      docker exec \
          -u postgres \
          -e PGPASSWORD=$PSQL_PASSWORD \
          $PSQL_CONTAINER \
            psql postgres --username=$PSQL_USER -f /database.sql

    docker exec $PSQL_CONTAINER rm /database.sql
    cd ..
    log "Done restore of db"

    exit 0

    log "Start restore of the filestore"
    cd filestore/
    # RM old data
    # Create directory
    docker exec --user 101 $ODOO_CONTAINER mkdir -p "/var/lib/odoo/filestore/$BACKUP_DB/"
    # Clean old data
    docker exec --user 0 $ODOO_CONTAINER rm -rf "/var/lib/odoo/filestore/$BACKUP_DB/*"
    #docker exec --user 0 $ODOO_CONTAINER chown -R odoo.odoo "/var/lib/odoo/filestore/$BACKUP_DB/"
    #docker exec --user 0 $ODOO_CONTAINER chmod -R 775 "/var/lib/odoo/filestore/$BACKUP_DB/"
    # Transfer files via tar hack
    #
    tar -cf - * \
      --mode u=+r,g=-rwx,o=-rwx \
      --owner 101 \
      --group 102 \
        | docker cp - $ODOO_CONTAINER:"/var/lib/odoo/filestore/$BACKUP_DB/"
    # Restore ownership 
    
    # Restore files permisions
    docker exec --user 0 $ODOO_CONTAINER chmod -R 755 "/var/lib/odoo/filestore"
    docker exec --user 0 $ODOO_CONTAINER chown -R odoo.odoo "/var/lib/odoo/filestore"
    # List files
    docker exec --user 102:102 $ODOO_CONTAINER sh -c 'ls -ahl /var/lib/odoo/filestore/$BACKUP_DB/*'
    cd ..
    log "Done restore of filestore"

    cd $CURRENT_PATH
    log "Application is restored/imported!"
    status_odoo
  else
    log "Restore procedure was canceled - DB: $RESTORE_DB date: $RESTORE_DATE file: $1"
  fi
}

restore_adodons_procedure() {
  restore_check
  log "Clean all previous restore data"
  rm -rf restore/tmp/* || true
  log "Restore  procedure of addons initiated: $1"
  #echo $$ > restore/tmp/.restore
  cd restore/tmp
  tar -xf ../$1 -C .
  du addons/
  #rm restore/tmp/.restore
  #rm -rf restore/tmp/*
  RESTORE_DB=$(cat "$CURRENT_PATH/restore/tmp/db/.database")
  RESTORE_DATE=$(cat "$CURRENT_PATH/restore/tmp/db/.backup_date")
  log "Addons to restore"
  log "Database date: $RESTORE_DATE"
  read -p "Are you sure? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Start restore of addons"
      cd addons/
      # Create direcrory if not exist
      docker exec --user 101:102 $ODOO_CONTAINER mkdir -p "/etc/odoo/addons/"
      #Clean old data
      #docker exec --user 101:102 $ODOO_CONTAINER rm -rf "/etc/odoo/addons/*"
      # Transfer files via tar hack
      tar -cf - * --mode u=+r,g=-rwx,o=-rwx --owner 101 --group 102 | docker cp - $ODOO_CONTAINER:"/etc/odoo/addons/"
      # restore permisions - user: odoo group: odoo
      docker exec --user 0 $ODOO_CONTAINER chown -R odoo:odoo "/etc/odoo/addons"
      # restore permisions to 755
      docker exec --user 0 $ODOO_CONTAINER chmod -R 755 "/etc/odoo/addons"
      # List files
      docker exec --user 1000:1000 $ODOO_CONTAINER sh -c 'ls -ahl /etc/odoo/addons/*'
      cd ..
      log "Done restore of addons"
  fi
}

restore_addons() {
  log "Start restore addons procedure"
    
  unset options i
  while IFS= read -r -d $'\0' f; do
    options[i++]="$f"
  # put sorted listinf or backup archives files into into a list
  done < <(find $BACKUP_PATH/$ODOO_DATABASE/ -maxdepth 1 -type f -name "odoo_backup*.gz" -print0 | sort -z)
  # select archive to restore
  select opt in "${options[@]}" "Select number of backup to restore"; do
    case $opt in
      *.gz)
        restore_adodons_procedure $opt
        break
        ;;
      "end")
        echo "You chose to stop"
        break
        ;;
      *)
        echo "This is not a correct database archive choosed"
        ;;
  esac
  done
}

restore_odoo() {
  #log "List of files:"
  #ls -a $BACKUP_PATH/$ODOO_DATABASE/*.gz | sort -k1,1
  log "Start restore procedure"
    
  unset options i
  while IFS= read -r -d $'\0' f; do
    options[i++]="$f"
  # put sorted listinf or backup archives files into into a list
  done < <(find $BACKUP_PATH/$ODOO_DATABASE/ -maxdepth 1 -type f -name "odoo_backup*.gz" -print0 | sort -z)
  # select archive to restore
  select opt in "${options[@]}" "Select number of backup to restore"; do
    case $opt in
      *.gz)
        mkdir -p restore/tmp
        log "Clean all previous restore data"
        rm -rf restore/tmp/* || true
        cd restore/tmp
        restore_check
        log "Restore procedure of archive initiated: $1"
        echo $$ > .restore
        restore_procedure $opt
        break
        ;;
      "end")
        echo "You chose to stop"
        break
        ;;
      *)
        echo "This is not a correct database archive choosed"
        ;;
    esac
  done
}

export_odoo() {
  log "Exporting data to external server"
  log "Export from: ./export/$ODOO_DATABASE/ to:$EXPORT_PATH"
  log "Migrate database from:$ODOO_DATABASE to:$EXPORT_DB" 

  mkdir -p export/$ODOO_DATABASE
  cd export/$ODOO_DATABASE
  backup_odoo export
  cd $CURRENT_PATH

  # untar filestore
  log "Unzip database.sql.gz"
  cd $CURRENT_PATH/export/tmp/db
  gzip -d database.sql.gz

  log "Find and replace in sql file: from $BACKUP_DB to $EXPORT_DB"
  sed -i -e 's/DROP DATABASE "'"$BACKUP_DB"'";/DROP DATABASE "'"$EXPORT_DB"'";/g' database.sql
  sed -i -e 's/CREATE DATABASE "'"$BACKUP_DB"'" WITH/CREATE DATABASE "'"$EXPORT_DB"'" WITH/g' database.sql
  sed -i -e 's/-- Name: '"$BACKUP_DB"'; Type: DATABASE;/-- Exported: '"$BACKUP_DB"'; Date: '"$NOW"' Type: DATABASE;/g' database.sql
  sed -i -e 's/ALTER DATABASE "'"$BACKUP_DB"'" OWNER/ALTER DATABASE "'"$EXPORT_DB"'" OWNER/g' database.sql
  sed -i -e 's/\\connect.*/\\connect -reuse-previous=on '"$EXPORT_DB"'/g' database.sql
  gzip database.sql

  cd $CURRENT_PATH/export/tmp/
  log "Archive and compress data before transfer"
  tar -czf ../import.$EXPORT_DB.$NOW.tar.gz .
  cd ..
  log "Archive to be exported size:"
  ls -la import.$EXPORT_DB.$NOW.tar.gz

  log "Start transfer data to: $EXPORT_PATH"
  rsync -avz import.$EXPORT_DB.$NOW.tar.gz $EXPORT_PATH
  log "Finished export of data"

  cd $CURRENT_PATH

}

import_odoo() {
  log "Start import data procedure"
  
  unset options i
  
  while IFS= read -r -d $'\0' f; do
    options[i++]="$f"
  # put sorted listinf or backup archives files into into a list

  done < <(find $CURRENT_PATH/import -maxdepth 1 -type f -name "import.$ODOO_DATABASE.*" -print0 | sort -z)
  # select archive to restore
  select opt in "${options[@]}" "Select number of backup to import:"; do
    case $opt in
      *.gz)
        log "Start import procedure on $opt"
        mkdir -p import/tmp
        log "Clean all previous restore data"
        rm -rf import/tmp/* || true
        cd import/tmp
        restore_check
        log "Restore procedure of archive initiated: $1"
        echo $$ > .restore
        restore_procedure $opt
        break

        break
        ;;
      "end")
        echo "You decided to cancel"
        break
        ;;
      *)
        echo "This is not a correct database archive choosed"
        ;;
    esac
  done
  cd $CURRENT_PATH
}

#Check arguments passed to script
usage() { echo "$0 script usage:" && grep " .)\ #" $0; exit 0; }
[ $# -eq 0 ] && usage
logmessage=""
while getopts "c:bm:hrup:i" arg; do
  case $arg in
    c) # Specify configuration file name -c .odoo.conf (default).
        CONFIG_FILE=${OPTARG}
        ;;
    p) # Start procedure
        PROCEDURE=${OPTARG}
        #check later
      ;;
    m) # Print message to the log file .logfile, example: ./odoo-docker.sh -m "Attempt to restore #5" -p restore, will print Attemp to restore #5 and start restore procedure.
        logmessage=$OPTARG
      ;;
    h | *) # Display help.
      usage
      #exit 0
      ;;
  esac
done

# Load configuration file
if [ -f "$CONFIG_FILE" ]; then
    echo "Configuration file [$CONFIG_FILE] has been loaded."
    CONFIG_CONTENT=$(cat $CONFIG_FILE| sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
    eval "$CONFIG_CONTENT"
else 
    echo "Cofig file $CONFIG_FILE does not exist."
    exit 1
fi

#Log admin's message to logfile if -m "Text message" used
[[ ! -z "$logmessage" ]] && log "Admin's logged to file: $logmessage"

NOW=`date '+%Y%m%d-%H%M%S'`
echo "Date: $NOW"

case $PROCEDURE in
  startall) #Start all odoo docker containers
    start_postgres
    start_odoo
    ;;
  startdb) #Start postgesql container
    start_postgres
    ;;
  start) #Start docker containers
    start_odoo
    ;;
  stopall) #Start docker containers
    stop_postgres
    stop_odoo
    docker ps
    ;;

  stop) #Start docker containers
    stop_odoo
    docker ps
    ;;

  status) #status
    status_postgres
    status_odoo
    ;;

  list) # List of backups
    backup_list
    ;;
  
  backup) # Backup current application
    backup_odoo
    ;;
  
  restore) # Restore application from backup (database and filestore)
    restore_odoo
    ;;

  restore_addons) # Restore addons only
    restore_addons
    ;;

  log) #check logfile
    docker logs $ODOO_CONTAINER
    ;;

  restart) #Start docker containers
    #restart_postgres
    ;;

  build) #Start docker containers
    #build postgress
    odoo_build
    #start_postgres
    exit 0
    ;;

  prebuild) #Prebuild all local dependencies
    #build postgress
    odoo_prebuild
    ;;

  export) #Export data 
    export_odoo
    ;;

  import) #Import data 
    import_odoo
    ;;

  adminer) #Start docker containers
    docker stop adminer
    #docker build dockette/adminer:pgs
    docker rm adminer
    docker run \
        --rm \
        -e MEMORY=512M \
        -e UPLOAD=4096M \
        --name adminer \
        --link $PSQL_CONTAINER:db \
        -d \
        -p $ADMINER_PORT:80 \
        dockette/adminer
    IP=$(echo $(hostname -I) | cut -d' ' -f 1)
    echo "Adminer is running on:"
    tput setaf 2; echo "http://$IP:$ADMINER_PORT/?server=$PSQL_CONTAINER&$username=admin&BACKUP_DB"; tput setaf 7;
    ;;

  help | *) # Display help.
    echo "Start process: odoo-docker.sh -p with options:"
    echo "-p help: shows this help"
    echo "-p startall: start containers"
    echo "-p status: Odoo and psql status"
    echo "-p stopall: odoo status"
    echo "-p log: Show Odoo's log file"
    echo "-p build:"
    echo "-p prebuild:"
    echo "-p restart: restart"
    echo "-p backup: backup configured database, filestore and addons"
    echo "-p restore: restore configured database and filesstore (addons manually only)"
    echo "-p export: export db, addons, filestore to local or remote location"
    echo "-p import: import db, addons, filestore"
    echo "-p adminer:  start adminer container to check PSQL database. Good for staging and dev servers."
    exit 0
    ;;
esac