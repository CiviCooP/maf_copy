#! bin/bash

# Settings
EXTENSION_DIR="sites/default/civicrm_extensions"

SRC_PATH=""
SRC_DRUPAL_DB=""
SRC_CIVICRM_DB=""
SRC_HOSTNAME=""

SRC_MYSQL_USER=""
SRC_MYSQL_PASS=""
SRC_MYSQL_HOST=""

SRC_EXTENSION_DIR=$SRC_PATH/$EXTENSION_DIR

DEST_PATH=""
DEST_DRUPAL_DB=""
DEST_CIVICRM_DB=""
DEST_HOSTNAME=""

DEST_MYSQL_USER="$SRC_MYSQL_USER"
DEST_MYSQL_PASS="$SRC_MYSQL_PASS"
DEST_MYSQL_HOST="$SRC_MYSQL_HOST"

DEST_EXTENSION_DIR=$DEST_PATH/$EXTENSION_DIR

TEMP_DIR="/tmp"
BACKUP_DIR=""