#!/bin/bash

set -ev
git_tag=`git describe --tags`

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
rake container:build_prod
docker tag muell ${DOCKER_IMAGE_NAME}:${git_tag}
docker push ${DOCKER_IMAGE_NAME}:${git_tag}
docker tag muell ${DOCKER_IMAGE_NAME}:latest
docker push ${DOCKER_IMAGE_NAME}:latest
