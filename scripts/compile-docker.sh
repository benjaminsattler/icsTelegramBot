#!/bin/bash

echo "This script builds some docker images that are required for rspec and rubocop."

echo "1/3: Build rubocop image"
docker build -t muell_rubocop --rm -f docker/rubocop/Dockerfile $PWD

echo "2/3: Build rspec image"
docker build -t muell_rspec --rm -f docker/rspec/Dockerfile $PWD

echo "3/3: Build dbmate image"
docker build -t muell_dbmate --rm -f docker/migrations/Dockerfile $PWD
