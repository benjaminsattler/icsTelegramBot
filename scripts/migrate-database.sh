#!/bin/bash

env=$ICSBOT_ENV
BASE_DIR=$(dirname $BASH_SOURCE)/../

if [ "$env" == "" ]; then
        env="testing"
    else
        env=$ICSBOT_ENV
    fi 

case $env in
    production)
        config=${BASE_DIR}config/prod.yml
        ;;
    testing)
        config=${BASE_DIR}config/test.yml
        ;;
esac

echo Environment is $env
echo Config is $config

if [ ! -f $config ]; then
    echo Could not read config file $config. Wrong environment?
    exit 1
fi

db_file=${BASE_DIR}`cat $config | grep db_path | awk -F ":" '{gsub(/[ \t]+/, "", $2);print $2}'`

echo Database file is $db_file
if [ ! -f $db_file ]; then
    echo Could not find database file $db_file.
    #exit 1
fi

case `uname -s` in
    Darwin)
        dbmate_binary=${BASE_DIR}bin/dbmate/dbmate
        ;;
    Linux)
        dbmate_binary=${BASE_DIR}bin/dbmate/dbmate-linux-amd64
        ;;
esac

echo Migration binary is $dbmate_binary

if [ ! -f "$dbmate_binary" ]; then
    echo Could not find dbmate binary $dbmate_binary
    exit 1
fi

echo Executing migrations
DB="sqlite://${db_file}" ${dbmate_binary} --migrations-dir "${BASE_DIR}/db/migrations/" -e DB $*
echo Finished executing migrations
