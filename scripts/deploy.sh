#!/bin/bash

BASE_DIR=`dirname $BASH_SOURCE`/../
source ${SCRIPT_DIR}config/deployment.sh

ssh -t $sshurl "cd ${sshlocaldir} && git fetch && git checkout master && git merge -S --no-ff origin/development && git push origin master && bundle install && ICSBOT_ENV=production ./scripts/migrate-database.sh migrate && ./scripts/restart-bot-production.sh"
