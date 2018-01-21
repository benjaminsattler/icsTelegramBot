#!/bin/bash

SCRIPT_DIR=$(dirname $BASH_SOURCE)/
BASE_DIR=${SCRIPT_DIR}../
SRC_DIR=${BASE_DIR}db/
DEST_DIR=${BASE_DIR}db/backup/

source ${BASE_DIR}config/backup.sh

if [ "$GDRIVE_BINARY" == "" ]; then
    GDRIVE_BINARY=gdrive
fi

if [ "$MAIL_BINARY" == "" ]; then
    MAIL_BINARY=mutt
fi

valid_gdrive_binary=0
`$GDRIVE_BINARY version >/dev/null 2>&1` && valid_gdrive_binary=1 || valid_gdrive_binary=0

if [ "$valid_gdrive_binary" -eq 1 ]; then
    echo Found gdrive executable $GDRIVE_BINARY
else
    echo "Could not find gdrive executable. Please install it from https://github.com/prasmussen/gdrive and make sure the variable GDRIVE_BINARY points to it."
    exit -1
fi

valid_mail_binary=0
`$MAIL_BINARY -v > /dev/null 2>&1` && valid_mail_binary=1 || valid_mail_binary=0

if [ "$valid_mail_binary" -eq 1 ]; then
    echo Found mail executable $MAIL_BINARY
else
    echo "Could not find mail binary. Please install mutt!"
    exit -1
fi

if [ ! -f "$DEST_DIR" ]; then
    echo Destination directory $DEST_DIR does not exist. Trying to create it...
    mkdir -p $DEST_DIR
fi

echo Looking for eligible files
for dbfile in ${SRC_DIR}*.db; do
    echo Found eligible file $dbfile
    datetime=`date +%Y%m%d_%H%M%S`
    basefname=`basename $dbfile .db`
    tgtfilename=${basefname}_${datetime}.db
    tgtencfilename=${tgtfilename}.enc
    tgtkeyfilename=${basefname}_${datetime}.db.key
    echo working file will be $tgtfilename
    echo encrypted file will be $tgtencfilename
    echo key file will be $tgtkeyfilename
    echo Copying file
    error=0
    cp $dbfile ${DEST_DIR}${tgtfilename}
    if [ -e ${DEST_DIR}${tgtfilename} ]; then
        echo Encrypting file
        ${SCRIPT_DIR}encrypt-file.sh ${DEST_DIR}${tgtfilename} $public_key_file ${DEST_DIR}${tgtkeyfilename} ${DEST_DIR}${tgtencfilename}
        if [ "$?" -eq "0" -a -e ${DEST_DIR}${tgtencfilename} -a -e ${DEST_DIR}${tgtkeyfilename} ]; then
            echo Uploading encrypted database to google drive
            if $GDRIVE_BINARY upload -p $gdrive_backup_folder_id ${DEST_DIR}${tgtencfilename}; then
                echo Successfully uploaded file to google drive
                echo Sending encrypted key via mail 
                if $MAIL_BINARY -s "$mail_subject" -a ${DEST_DIR}${tgtkeyfilename} -- "$mail_rcpt" < $mail_txt_file; then
                    echo Successfully sent mail
                else
                    error=1
                fi
                
            else
                error=1
            fi
        else
            error=1
        fi
    else
        error=1
    fi

    if [ "$error" -eq "1" ]; then
        echo ERROR!
        echo Trying to delete any leftover artifacts
        rm -f ${DEST_DIR}${tgtfilename} ${DEST_DIR}${tgtencfilename} ${DEST_DIR}${tgtkeyfilename}
    fi
done
