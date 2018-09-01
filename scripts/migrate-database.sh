#!/bin/bash

source `dirname $BASH_SOURCE`/../docker/migrations/docker.env
docker run --rm -v $PWD/db/:/db --env-file $PWD/docker/migrations/docker.env --network=muell_backend muell_dbmate --migrations-dir $MIGRATIONS_DIR $*
