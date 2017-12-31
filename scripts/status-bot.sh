#!/bin/bash
SCRIPT_DIR=$(dirname $BASH_SOURCE)
PIDFILE=$SCRIPT_DIR/../out/bot.pid
PID=`cat $PIDFILE`
STATUS="unknown"
echo Status of Bot...
if [ "$PID" = "" ]; then
    STATUS="stopped"
else
    echo Found PID $PID
    STAT=`ps -o stat= -p $PID`
    STAT=`echo $STAT | sed 's/^ *//;s/ *$//'`

    case $STAT in
        S)
            STATUS="running"
            ;;
    esac
fi
echo Status is $STATUS
