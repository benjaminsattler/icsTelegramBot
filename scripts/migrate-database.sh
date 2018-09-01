#!/bin/bash

source `dirname $BASH_SOURCE`/../docker/migrations/docker.env
docker-compose run migrations --migrations-dir $MIGRATIONS_DIR $*
