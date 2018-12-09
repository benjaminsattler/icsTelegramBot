#!/bin/bash

openssl aes-256-cbc -K $encrypted_31ee9ec10cd4_key -iv $encrypted_31ee9ec10cd4_iv -in docker/production.env.enc -out docker/production.env -d && \
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin && \
rake docker:build_push_prod && \
rake hyper:update
