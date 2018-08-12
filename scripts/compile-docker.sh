#!/bin/bash

echo "This script builds some docker images that are required for rspec and rubocop."

echo "1/2: Build rubocop image"
docker build -t muell_rubocop --rm $PWD/docker/rubocop

echo "2/2: Build rspec image"
docker build -t muell_rspec --rm $PWD/docker/rspec
