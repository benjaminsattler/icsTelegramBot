-- migrate:up
CREATE TABLE notification_log(
  id_notification_log INT NOT NULL AUTO_INCREMENT,
  telegram_id INT NOT NULL,
  event_id VARCHAR(255) NULL,
  calendar_id INT NOT NULL,
  message_timestamp DATETIME NOT NULL DEFAULT '1000-01-01 00:00:00',
  PRIMARY KEY(id_notification_log),
  UNIQUE INDEX(telegram_id, event_id, calendar_id)
);

-- migrate:down
DROP TABLE notification_log;
