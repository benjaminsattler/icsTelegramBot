#!/bin/bash

echo "Starting muell service"
docker run -v $PWD/:/app -v $PWD/assets/:/assets -v $PWD/db/:/db -v $PWD/log/:/log --network=muell_frontend muell
