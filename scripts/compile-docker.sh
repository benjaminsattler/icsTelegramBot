#!/bin/bash

echo "This script builds some docker images that are required for rspec and rubocop."

echo "1/4: Build production image"
docker build -t muell --rm -f docker/app-production/Dockerfile $PWD

echo "2/4: Build rubocop image"
docker build -t muell_rubocop --rm -f docker/rubocop/Dockerfile $PWD

echo "3/4: Build rspec image"
docker build -t muell_rspec --rm -f docker/rspec/Dockerfile $PWD

echo "4/4: Build dbmate image"
docker build -t muell_dbmate --rm -f docker/migrations/Dockerfile $PWD
