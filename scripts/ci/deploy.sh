#!/bin/bash

set -ev

git_tag=`git describe --tags | head -n 1`
gce_image_name="${GCE_REGISTRY_HOST}/${K8S_PROJECT_NAME}/${GCE_DOCKER_IMAGE_NAME}"

echo $GCE_DOCKER_LOGIN > k8s/secrets/gce.json
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
docker login -u _json_key --password-stdin https://eu.gcr.io < k8s/secrets/gce.json
gcloud --quiet beta auth configure-docker
gcloud --quiet auth activate-service-account --key-file ./k8s/secrets/gce.json
gcloud --quiet --project ${K8S_PROJECT_NAME} container clusters get-credentials ${K8S_CLUSTER_NAME} --zone ${K8S_CLUSTER_ZONE}
rake container:build_prod
docker tag muell ${DOCKER_IMAGE_NAME}:${git_tag}
docker push ${DOCKER_IMAGE_NAME}:${git_tag}
docker tag muell ${DOCKER_IMAGE_NAME}:latest
docker push ${DOCKER_IMAGE_NAME}:latest
docker tag muell ${gce_image_name}:${git_tag}
docker push ${gce_image_name}:${git_tag}
docker tag muell ${gce_image_name}:latest
docker push ${gce_image_name}:latest
kubectl set image deployment/${K8S_DEPLOYMENT_NAME} ${K8S_DEPLOYMENT_CONTAINER_NAME}=${gce_image_name}:latest
kubectl rollout status deployments/${K8S_DEPLOYMENT_NAME}
