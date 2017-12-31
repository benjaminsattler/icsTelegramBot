#!/bin/bash
SCRIPT_DIR=$(dirname $BASH_SOURCE)
PIDFILE=$SCRIPT_DIR/../out/bot.pid

echo Starting Bot...
nohup ruby $SCRIPT_DIR/../src/main.rb  &> $SCRIPT_DIR/../out/nohup.out&
PID=$!
echo "Started with PID $PID"
echo -n $PID > $PIDFILE
