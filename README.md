# maf_copy
Script for copying live to test for MAf Norge

## Usage Copy live to test

    $ ./maf_copy.sh

## Usage backup functionality

    $ ./maf_backup.sh

## Installation instructions

    $ git clone https://github.com/CiviCooP/maf_copy.git
    $ cd maf_copy
    $ cp parameters.dist.sh parameters.sh

Fill in the details of your installation, e.g. paths and mysql username and password

    $ nano parameters.sh

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
    

