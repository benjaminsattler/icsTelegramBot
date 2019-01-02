#!/bin/bash

set -ev
curl https://sdk.cloud.google.com | bash > /dev/null
source $HOME/google-cloud-sdk/path.bash.inc
gcloud --quiet components list
gcloud --quiet components update
gcloud --quiet components install beta kubectl docker-credential-gcr
gcloud --quiet version
