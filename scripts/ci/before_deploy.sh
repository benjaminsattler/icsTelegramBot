#!/bin/bash

wget -O google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-228.0.0-linux-x86_64.tar.gz && \
tar xvvf google-cloud-sdk.tar.gz && \
./google-cloud-sdk/install.sh --quiet && \
source ./google-cloud-sdk/path.bash.inc && \
gcloud --quiet components update && \
gcloud --quiet components install kubectl && \
gcloud --quiet version
