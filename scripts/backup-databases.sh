#!/bin/bash

BASE_DIR=$(dirname $BASH_SOURCE)/../
SRC_DIR=${BASE_DIR}db/
DEST_DIR=${BASE_DIR}db/backup/

source ${BASE_DIR}config/backup.sh

if [ "$GDRIVE_BINARY" == "" ]; then
    GDRIVE_BINARY='gdrive'
fi

valid_binary=0
`$GDRIVE_BINARY version >/dev/null 2>&1` && valid_binary=1
`$GDRIVE_BINARY version >/dev/null 2>&1` || valid_binary=0

if [ "$valid_binary" -eq 1 ]; then
    echo Found executable $GDRIVE_BINARY
else
    echo "Could not find gdrive executable. Please install it from https://github.com/prasmussen/gdrive and make sure the variable GDRIVE_BINARY points to it."
    exit -1
fi

if [ ! -f "$DEST_DIR" ]; then
    echo Destination directory $DEST_DIR does not exist. Trying to create it...
    mkdir -p $DEST_DIR
fi

echo Looking for eligible files
for dbfile in ${SRC_DIR}*.db; do
    echo Found eligible file $dbfile
    cp $dbfile $DEST_DIR/`basename $dbfile .db`_`date +%Y%m%d_%H%M%S`.db
done

echo Starting upload to google drive
$GDRIVE_BINARY sync upload $DEST_DIR $gdrive_backup_folder_id
