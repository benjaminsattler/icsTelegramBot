#!/bin/bash

BASE_DIR=`dirname $BASH_SOURCE`/../
source ${SCRIPT_DIR}config/deployment.sh

ssh $sshurl "cd ${sshlocaldir} && git pull && $sshafterupdate"
