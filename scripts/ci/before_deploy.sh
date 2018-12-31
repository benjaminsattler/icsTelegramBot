#!/bin/bash

set -ev
curl https://sdk.cloud.google.com | bash > /dev/null
gcloud --quiet components list
gcloud --quiet components update
gcloud --quiet components install beta kubectl docker-credential-gcr
gcloud --quiet version
