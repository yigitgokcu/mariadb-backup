#!/bin/sh

 ### VARIABLES ###
 BACKUP_DIR="/path/to/mysql_backup/"
 DB_USER=<USER>
 DB_USER_PASS=<PASS>
 REMOTE_SERVER=<REMOTE_IP_ADDRESS>
 REMOTE_SERVER_DATA_PATH="<MYSQL_DATA_PATH>"
 ###

 echo "Creating Backup Directory"
 mkdir -p $BACKUP_DIR

 echo "Removing old files"
 rm -rf  $BACKUP_DIR/*

 echo "Creating Backup…."
 mariabackup --backup --galera-info\
    --target-dir=$BACKUP_DIR \
    --user=$DB_USER \
    --password=$DB_USER_PASS
 echo "Backup Created"

 echo "Removing old files on remote server"
 ssh root@$REMOTE_SERVER "rm -rf  $BACKUP_DIR/*"

 echo "Syncing Files…"
 rsync -argop /$BACKUP_DIR/* root@$REMOTE_SERVER:/$BACKUP_DIR/

# Restore Section for Remote MySQL

 echo "Stopping MySQL"
 ssh root@$REMOTE_SERVER "systemctl stop mariadb "

 echo "Preparing…"
 ssh root@$REMOTE_SERVER "mariabackup --prepare  --innodb-log-buffer-size=1024M --use-memory=2G --target-dir=/$BACKUP_DIR/"

 echo "Removing old MySQL files…"
 ssh root@$REMOTE_SERVER "cd $REMOTE_SERVER_DATA_PATH && rm -rf *"

 echo "Copy prepared files…"
 ssh root@$REMOTE_SERVER "cp -pR /$BACKUP_DIR/* /$REMOTE_SERVER_DATA_PATH/"

 echo "Setting Owners"
 ssh root@$REMOTE_SERVER "chown -R mysql. $REMOTE_SERVER_DATA_PATH"

 echo "Restarting…"
 ssh root@$REMOTE_SERVER "systemctl start mariadb"
 echo "Done"
