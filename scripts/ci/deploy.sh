#!/bin/bash

git_tag=`git describe --tags | head -n 1`
gce_image_name="${GCE_REGISTRY_HOST}/${K8S_PROJECT_NAME}/${GCE_DOCKER_IMAGE_NAME}"

source ./google-cloud-sdk/path.bash.inc && \
openssl aes-256-cbc -K $encrypted_8f5a1ceb36fa_key -iv $encrypted_8f5a1ceb36fa_iv -in k8s/secrets/gce.json.enc -out k8s/secrets/gce.json -d && \
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin && \
gcloud --quiet auth configure-docker && \
gcloud --quiet auth activate-service-account --key-file ./k8s/secrets/gce.json && \
gcloud --quiet --project ${K8S_PROJECT_NAME} container clusters get-credentials ${K8S_CLUSTER_NAME} --zone ${K8S_CLUSTER_ZONE} && \
rake container:build_prod && \
docker login && \
ocker tag muell ${DOCKER_IMAGE_TAG}:${git_tag} && \
docker push ${DOCKER_IMAGE_TAG}:${git_tag} && \
docker tag muell ${DOCKER_IMAGE_TAG}:latest && \
docker push ${DOCKER_IMAGE_TAG}:latest && \
docker tag muell ${gce_image_name}:${git_tag} && \
docker push ${gce_image_name}:${git_tag} && \
docker tag muell ${gce_image_name}:latest && \
docker push ${gce_image_name}:latest && \
kubectl set image deployment/${K8S_DEPLOYMENT_NAME} ${K8S_DEPLOYMENT_CONTAINER_NAME}=${gce_image_name}:latest && \
kubectl rollout status deployments/${K8S_DEPLOYMENT_NAME}
