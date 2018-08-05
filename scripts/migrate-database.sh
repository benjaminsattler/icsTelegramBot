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

persistence=`cat $config | grep persistence | awk -F ":" '{gsub(/[ \t]+/, "", $2);print $2}'`
echo "Persistence is $persistence"
case "$persistence" in
    "sqlite")
        db_path=`cat $config | grep db_path | awk -F ":" '{gsub(/[ \t]+/, "", $2);print $2}'`
        db_file="sqlite://$db_path"
        ;;
    "mysql")
        db_host=`cat $config | grep host | awk -F ":" '{gsub(/[ \t]+/, "", $2);print $2}'`
        db_port=`cat $config | grep port | awk -F ":" '{gsub(/[ \t]+/, "", $2);print $2}'`
        db_username=`cat $config | grep username | awk -F ":" '{gsub(/[ \t]+/, "", $2);print $2}'`
        db_password=`cat $config | grep password | awk -F ":" '{gsub(/[ \t]+/, "", $2);print $2}'`
        db_database=`cat $config | grep database | awk -F ":" '{gsub(/[ \t]+/, "", $2);print $2}'`
        db_file="mysql://$db_username:$db_password@$db_host:$db_port/$db_database"
        ;;
esac

echo Database file is $db_file

if [ "$DBMATE_BINARY" != "" ]; then
    dbmate_binary=$DBMATE_BINARY
else
    case `uname -s` in
        Darwin)
            dbmate_binary=${BASE_DIR}bin/dbmate/dbmate
            ;;
        Linux)
            dbmate_binary=${BASE_DIR}bin/dbmate/dbmate-linux-amd64
            ;;
    esac
fi
echo Migration binary is $dbmate_binary

echo Executing migrations
DB=$db_file $dbmate_binary --migrations-dir "${BASE_DIR}/db/migrations/$persistence/" -e DB $*
echo Finished executing migrations
