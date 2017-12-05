#!/bin/sh

DATE=$(date +%Y-%m-%d-%H-%M)
export PGPASSWORD=$POSTGRESQL_PASSWORD
pg_dump --username=$POSTGRESQL_USER --host=$POSTGRESQL_SERVICE_HOST --port=$POSTGRESQL_SERVICE_PORT $POSTGRESQL_DATABASE > /tmp/dump.sql

if [ $? -ne 0 ]; then
    echo "db-dump not successful: ${DATE}"
    exit 1
fi

BACKUP_FILENAME=dump-${DATE}.sql.gz

gzip -c /tmp/dump.sql > $BACKUP_DATA_DIR/$BACKUP_FILENAME

BACKUP_CREATED=$?

rm -f /tmp/dump.sql

if [ $BACKUP_CREATED -eq 0 ]; then
    echo "backup created: ${DATE}"
else
    echo "backup not successful: ${DATE}"
    exit 1
fi

# Delete old files
old_dumps=$(ls -1 $BACKUP_DATA_DIR/dump* | head -n -$BACKUP_KEEP)
if [ "$old_dumps" ]; then
    echo "Deleting: $old_dumps"
    rm $old_dumps
fi

#Copy backup to EkoServ (rugby DB "proxy")
scp -p -i /.eko_ssh/ssh-privatekey -o StrictHostKeyChecking=no $BACKUP_DATA_DIR/$BACKUP_FILENAME $EKOSERVER_USER@$EKOSERVER_HOST:/home/ekouser/HTS2Backups/$BACKUP_FILENAME
echo "[INFO] Backup sent to Eko server"

#Remove backup older than 8 days on EkoServer (careful, directory cannot use env value)
ssh -i /.eko_ssh/ssh-privatekey $EKOSERVER_USER@$EKOSERVER_HOST -o StrictHostKeyChecking=no 'find ~/HTS2Backups/ -maxdepth 1 -type f -name "*.backup*" -mtime +7 -exec rm {} \;'
echo "[INFO] Clean old backups on Eko server"


#TESTS COMMANDS
#scp -p -i /.eko_ssh/ssh-privatekey  $BACKUP_DATA_DIR/dump-2017-09-26-13-55.sql.gz $EKOSERVER_USER@$EKOSERVER_HOST:/home/ekouser/HTS2Backups/dump-test.sql.gz

#ssh -i /.eko_ssh/ssh-privatekey -o StrictHostKeyChecking=no -o UserKnownHostsFile=.eko_ssh/known_hosts $EKOSERVER_USER@$EKOSERVER_HOST