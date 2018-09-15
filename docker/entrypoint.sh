#!/bin/sh
dbmate wait && echo "Migrating..." && dbmate --no-dump-schema --migrations-dir ${MIGRATIONS_DIR} up && echo "Migration complete"
if [ "$ENABLE_DEBUG" == "1" ]; then
  rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 26162 -- $@
else
  exec $@
fi
