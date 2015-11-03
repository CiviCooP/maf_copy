#! /bin/bash
CURRENT_PWD=${PDW}
source parameters.sh
source echo_functions.sh

# backup files
backup_files() {
    cd $SRC_PATH
    cd ..
    tar -czf $BACKUP_FILE $SRC_NAME
    cd $CURRENT_PWD
    return 0
}

dump_database() {
    cd $BACKUP_DIR
    mysqldump_options="--add-drop-table --no-create-db --routines --triggers"
    mysqldump="mysqldump --user $SRC_MYSQL_USER --password=$SRC_MYSQL_PASS --host=$SRC_MYSQL_HOST $mysql_dump_options"
    $mysqldump $SRC_DRUPAL_DB | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | sed -e "s/$SRC_HOSTNAME/$DEST_HOSTNAME/" | gzip > $SRC_DRUPAL_DB-$BACKUP_FILE_SUFFIX.sql.gz
    $mysqldump $SRC_CIVICRM_DB | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > $SRC_CIVICRM_DB-$BACKUP_FILE_SUFFIX.sql.gz
    cd $CURRENT_PWD
    return 0
}

cd $SRC_PATH
BACKUP_FILE_PREFIX=${PWD##*/}
BACKUP_FILE_SUFFIX=$(date +%Y%m%d)
cd $CURRENT_PWD
BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE_PREFIX-$BACKUP_FILE_SUFFIX.tgz"

[ -d $DEST_PATH ] || mkdir $DEST_PATH
cd $DEST_PATH
DEST_NAME=${PWD##*/} 
cd $SRC_PATH
SRC_NAME=${PWD##*/} 
cd $CURRENT_PWD


action "Backup files" backup_files
action "Dump databases" dump_database

cd $CURRENT_PWD
exit 0
