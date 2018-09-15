#!/bin/sh
dbmate wait && echo "Migrating..." && dbmate --no-dump-schema --migrations-dir ${MIGRATIONS_DIR} up && echo "Migration complete"
rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 26162 -- $@
