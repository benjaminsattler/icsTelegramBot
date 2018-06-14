#!/bin/bash
BASE_DIR=$(dirname $BASH_SOURCE)/../
PIDFILE=${BASE_DIR}log/bot.pid
LOGFILE=${BASE_DIR}log/bot_${1}.log

echo Starting Bot...
if [ "$1" = "" ]; then
    echo "Please specify a running environment: testing or production!"
    exit
fi
export ICSBOT_ENV=$1
${BASE_DIR}bin/server --daemon --log=${LOGFILE} --pid=${PIDFILE} --main=MainThread
servercode=$? 
if [ -f $PIDFILE ] && [ "$servercode" -eq "0" ]; then
    echo "Started with PID `cat $PIDFILE`, ENVIRONMENT $ICSBOT_ENV and LOG $LOGFILE"
else
    echo "Failed to start server with exitcode $servercode!"
fi
