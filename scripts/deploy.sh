#!/bin/bash

BASE_DIR=`dirname $BASH_SOURCE`/../
source ${SCRIPT_DIR}config/deployment.sh

ssh -t $sshurl "cd ${sshlocaldir} && git checkout master && git pull && $sshafterupdate"
