#!/bin/bash

echo "This script builds some docker images that are required for rspec and rubocop."

echo "1/5: Build production image"
docker build -t muell --rm -f docker/app-production/Dockerfile $PWD

echo "2/5: Build development image"
docker build -t muell_dev --rm -f docker/app-devel/Dockerfile $PWD

echo "3/5: Build rubocop image"
docker build -t muell_rubocop --rm -f docker/rubocop/Dockerfile $PWD

echo "4/5: Build rspec image"
docker build -t muell_rspec --rm -f docker/rspec/Dockerfile $PWD

echo "5/5: Build dbmate image"
docker build -t muell_dbmate --rm -f docker/migrations/Dockerfile $PWD
