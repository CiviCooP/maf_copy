#! /bin/bash
CURRENT_PWD=$(pwd)
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
    cd $TEMP_DIR
    mysqldump_options="--add-drop-table --no-create-db --routines --triggers"
    mysqldump="mysqldump --user $SRC_MYSQL_USER --password=$SRC_MYSQL_PASS --host=$SRC_MYSQL_HOST $mysql_dump_options"
    $mysqldump $SRC_DRUPAL_DB | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | sed -e "s#$SRC_HOSTNAME#$DEST_HOSTNAME#" | gzip > $SRC_DRUPAL_DB-$BACKUP_FILE_SUFFIX.sql.gz
    $mysqldump $SRC_CIVICRM_DB | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > $SRC_CIVICRM_DB-$BACKUP_FILE_SUFFIX.sql.gz
    cd $CURRENT_PWD
    return 0
}

#copy database
copy_database() {
    cd $TEMP_DIR
    mysql="mysql --user $DEST_MYSQL_USER --password=$DEST_MYSQL_PASS --host=$DEST_MYSQL_HOST"
    $mysql -e "CREATE DATABASE IF NOT EXISTS \`$DEST_DRUPAL_DB\`;"
    $mysql -e "CREATE DATABASE IF NOT EXISTS \`$DEST_CIVICRM_DB\`;"

    zcat $SRC_DRUPAL_DB-$BACKUP_FILE_SUFFIX.sql.gz | $mysql --database=$DEST_DRUPAL_DB
    zcat $SRC_CIVICRM_DB-$BACKUP_FILE_SUFFIX.sql.gz | $mysql --database=$DEST_CIVICRM_DB
    cd $CURRENT_PWD
    return 0
}



update_drupal_database_settings() {
    #update drupal settings
    UPDATE_COLOR_SQL="UPDATE drupal_variable SET VALUE='a:9:{s:3:\"top\";s:7:\"#4c1c58\";s:6:\"bottom\";s:7:\"#593662\";s:2:\"bg\";s:7:\"#fffdf7\";s:7:\"sidebar\";s:7:\"#edede7\";s:14:\"sidebarborders\";s:7:\"#e7e7e7\";s:6:\"footer\";s:7:\"#2c2c28\";s:11:\"titleslogan\";s:7:\"#ffffff\";s:4:\"text\";s:7:\"#301313\";s:4:\"link\";s:7:\"#9d408d\";}' WHERE name='color_bartik_palette' OR name='color_civi_bartik_palette';"
    $mysql --database=$DEST_DRUPAL_DB -e "$UPDATE_COLOR_SQL"
    UPDATE_SITE_NAME="UPDATE drupal_variable SET VALUE='s:4:\"TEST\"' WHERE name = 'site_name';"
    $mysql --database=$DEST_DRUPAL_DB -e "$UPDATE_SITE_NAME"
    return 0
}

update_civicrm_extension_dir() {
    #UPDATE civicrm settings
    local PHP_CODE="echo serialize('$DEST_EXTENSION_DIR');"
    SERIALIZED_EXTENSION_DIR=`php -r "$PHP_CODE"`
    UPDATE_EXTENSION_DIR="UPDATE civicrm_setting SET value='$SERIALIZED_EXTENSION_DIR' WHERE name = 'extensionsDir';"
    $mysql --database=$DEST_CIVICRM_DB -e "$UPDATE_EXTENSION_DIR"
    return 0
}

update_civicrm_outbound_mail_setting() {
    #UPDATE outbound email
    CURRENT_OUTBOUND_EMAIL_SETTING=`$mysql -N --silent --database=$DEST_CIVICRM_DB -e "select value from civicrm_setting where name = 'mailing_backend'"`
    SERIALIZE_OUTBOUND_PHP_CODE="\$value = unserialize('$CURRENT_OUTBOUND_EMAIL_SETTING'); \$value['outBound_option'] = 5; echo serialize(\$value);"
    UPDATE_OUTBOUND_EMAIL_SETTING=`php -r "$SERIALIZE_OUTBOUND_PHP_CODE"`
    UPDATE_OUTBOUND_EMAIL="UPDATE civicrm_setting SET value = '$UPDATE_OUTBOUND_EMAIL_SETTING' WHERE name = 'mailing_backend';"
    $mysql --database=$DEST_CIVICRM_DB -e "$UPDATE_OUTBOUND_EMAIL"
    return 0
}

disable_sms_providers() {
    #CHANGE SMS providers
    UPDATE_SMS_PROVIDER="UPDATE civicrm_sms_provider SET username = 'a', password = 'a', api_url = 'a';"
    $mysql --database=$DEST_CIVICRM_DB -e "$UPDATE_SMS_PROVIDER"
    return 0
}

disable_scheduled_jobs() {
    #disable scheduled jobs
    DISABLE_JOBS="UPDATE civicrm_job SET is_active=0 WHERE api_action IN ('mail_report', 'process_pledge', 'process_respondent', 'process_mailing');"
    $mysql --database=$DEST_CIVICRM_DB -e "$DISABLE_JOBS"
    return 0
}

extract_files() {
    #extract backup
    tar -xf $BACKUP_FILE -C $TEMP_DIR
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
        mv $TEMP_DIR/$SRC_NAME $TEMP_DIR/$DEST_NAME
        chmod u+w $TEMP_DIR/$DEST_NAME/sites/default
        return 0
    fi
    return 1
}

update_civicrm_settings_file() {
    #change civicrm.settings.php
    chmod u+w $TEMP_DIR/$DEST_NAME/sites/default/civicrm.settings.php
    sed -i "s#mysql://$SRC_MYSQL_USER:$SRC_MYSQL_PASS@$SRC_MYSQL_HOST/$SRC_DRUPAL_DB?#mysql://$DEST_MYSQL_USER:$DEST_MYSQL_PASS@$DEST_MYSQL_HOST/$DEST_DRUPAL_DB?#" $TEMP_DIR/$DEST_NAME/sites/default/civicrm.settings.php
    sed -i "s#mysql://$SRC_MYSQL_USER:$SRC_MYSQL_PASS@$SRC_MYSQL_HOST/$SRC_CIVICRM_DB?#mysql://$DEST_MYSQL_USER:$DEST_MYSQL_PASS@$DEST_MYSQL_HOST/$DEST_CIVICRM_DB?#" $TEMP_DIR/$DEST_NAME/sites/default/civicrm.settings.php
    sed -i "s@$SRC_PATH/@$DEST_PATH/@" $TEMP_DIR/$DEST_NAME/sites/default/civicrm.settings.php
    sed -i "s@$SRC_HOSTNAME@$DEST_HOSTNAME@" $TEMP_DIR/$DEST_NAME/sites/default/civicrm.settings.php
    return 0
}

update_drupal_settings_file() {
    #change drupal.settings.php
    chmod u+w $TEMP_DIR/$DEST_NAME/sites/default/settings.php
    sed -i "s/'database' => '$SRC_DRUPAL_DB',/'database' => '$DEST_DRUPAL_DB',/" $TEMP_DIR/$DEST_NAME/sites/default/settings.php
    sed -i "s/'username' => '$SRC_MYSQl_USER',/'username' => '$DEST_MYSQl_USER',/" $TEMP_DIR/$DEST_NAME/sites/default/settings.php
    sed -i "s/'password' => '$SRC_MYSQl_PASS',/'password' => '$DEST_MYSQl_PASS',/" $TEMP_DIR/$DEST_NAME/sites/default/settings.php
    sed -i "s/'host' => '$SRC_MYSQl_HOST',/'host' => '$DEST_MYSQl_HOST',/" $TEMP_DIR/$DEST_NAME/sites/default/settings.php
    sed -i "s@$SRC_HOSTNAME@$DEST_HOSTNAME@" $TEMP_DIR/$DEST_NAME/sites/default/settings.php
    sed -i "s/=> '\`$SRC_CIVICRM_DB\`.',/=> '\`$DEST_CIVICRM_DB\`.',/" $TEMP_DIR/$DEST_NAME/sites/default/settings.php
    return 0
}

move_to_new_location() {
    #ok move to destination
    chmod -R u+w $DEST_PATH
    rm -rf $DEST_PATH
    mv $TEMP_DIR/$DEST_NAME $DEST_PATH
}

clean_up() {
    rm -rf $BACKUP_FILE
    cd $TEMP_DIR
    rm -rf $SRC_DRUPAL_DB-$BACKUP_FILE_SUFFIX.sql.gz
    rm -rf $SRC_CIVICRM_DB-$BACKUP_FILE_SUFFIX.sql.gz
    cd $CURRENT_PWD
}


cd $SRC_PATH
BACKUP_FILE_PREFIX=${PWD##*/}
BACKUP_FILE_SUFFIX=$(date +%Y%m%d)
cd $CURRENT_PWD
BACKUP_FILE="$TEMP_DIR/$BACKUP_FILE_PREFIX-$BACKUP_FILE_SUFFIX.tgz"

[ -d $DEST_PATH ] || mkdir $DEST_PATH
cd $DEST_PATH
DEST_NAME=${PWD##*/} 
cd $SRC_PATH
SRC_NAME=${PWD##*/} 
cd $CURRENT_PWD

PID_FILE="$CURRENT_PWD/pid"

if [ -e "$PID_FILE" ]
then
    echo -n "Script already running "
    echo_failure $"Script already running "
    echo
    exit 0
fi

echo "$(date +%Y%m%d%H%M)" > $PID_FILE
action "Backup files" backup_files
action "Extract backup" extract_files
action "Update CiviCRM's civicrm.settings.php" update_civicrm_settings_file
action "Update Drupal's settings.php" update_drupal_settings_file
action "Dump databases" dump_database
action "Copy databases" copy_database
action "Update drupal settings in database" update_drupal_database_settings
action "Update extension dir" update_civicrm_extension_dir
action "Redirect mail to database" update_civicrm_outbound_mail_setting
action "Disable SMS providers" disable_sms_providers
action "Disable scheduled jobs" disable_scheduled_jobs
action "Move files" move_to_new_location
action "Clean up" clean_up

rm -rf $PID_FILE

cd $CURRENT_PWD
exit 0
