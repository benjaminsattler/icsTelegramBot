#!/bin/bash

source ${SCRIPT_DIR}config/deployment.sh
IFS='' read -r -d '' SSH_COMMAND <<EOT
echo dir is $sshlocaldir
cd $sshlocaldir
git fetch --tags
git checkout master
bundle install
ICSBOT_ENV=production ./scripts/migrate-database.sh migrate
./scripts/restart-bot-production.sh
EOT

ssh $sshurl -i $sshkeyfile -t "${SSH_COMMAND}"
