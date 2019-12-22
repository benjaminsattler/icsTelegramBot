#!/bin/bash
if [[ "$TIMEZONE" == "" ]]; then
  echo "No timezone set, falling back to UTC."
  echo "To change timezone, set \$TIMEZONE to any"
  echo "value as listed here: "
  echo
  echo "https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
  echo
  TIMEZONE=UTC
fi

if [[ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]]; then
  echo "Invalid \$TIMEZONE value (${TIMEZONE}), falling back to UTC."
  echo "Valid values are listed here: "
  echo
  echo "https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
  echo
  TIMEZONE=UTC
fi
echo "Setting timezone to ${TIMEZONE}"
cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo "${TIMEZONE}" > /etc/timezone
if [[ "$ICSBOT_ENV" == "development" ]]; then
  echo "Waiting for database..." && dbmate wait && echo "Database is reachable."
fi
echo "Migrating..." && dbmate --no-dump-schema --migrations-dir ${MIGRATIONS_DIR} up && echo "Migration complete"
if [[ "$ENABLE_DEBUG" == "1" && "$ICSBOT_ENV" == "development" ]]; then
  rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 26162 -- $@
else
  ruby $@
fi
