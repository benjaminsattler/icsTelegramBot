#!/bin/sh
if [[ "$ICSBOT_ENV" == "development" ]]; then
  echo "Waiting for database..." && dbmate wait && echo "Database is reachable."
fi
echo "Migrating..." && dbmate --no-dump-schema --migrations-dir ${MIGRATIONS_DIR} up && echo "Migration complete"
if [[ "$ENABLE_DEBUG" == "1" && "$ICSBOT_ENV" == "development" ]]; then
  rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 26162 -- $@
else
  exec $@
fi
