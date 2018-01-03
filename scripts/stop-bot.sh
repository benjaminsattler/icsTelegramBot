#!/bin/bash

BASE_DIR=$(dirname $BASH_SOURCE)/../
PIDFILE=${BASE_DIR}log/bot.pid
PID=`cat $PIDFILE`
TIMEOUT=30
RETRIES=3

function killBot {
    ct=$TIMEOUT
    pid=$1
    kill $pid
    while [ "$ct"  -gt "0" ] && [ "$dead" -eq "0" ]
    do
        state=`ps -o state= -p $pid`
        if [ "$state" = "" ]; then
            echo "killed"
            dead=1
            return
        else
            echo "Waiting ($ct seconds...)"
        fi
        ct=$[$ct - 1]
        sleep 1
    done
}

try=1
dead=0
echo Stopping bot...
echo PID is $PID
while [ "$try" -le "$RETRIES" ]
do
    echo "Try $try of $RETRIES..."
    killBot $PID
    if [ "$dead" -eq "0" ]; then
        try=$[$try + 1]
    else
        try=$[$RETRIES + 1]
    fi
done

if [ "$dead" -eq "0" ]; then
    echo "Failed to kill bot."
else
    echo "Bot killed successfully."
    if [ -f $PIDFILE ]; then
        echo "ATTENTION: PID file still exists. Trying to delete manually."
        rm $PIDFILE
        if [ -f $PIDFILE ]; then
            echo "Failed to delete PID file."
        else
            echo "Deleted successfully."
        fi
    fi
fi

exit $dead
